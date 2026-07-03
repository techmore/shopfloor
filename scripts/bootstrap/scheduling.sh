#!/bin/bash
# =============================================================================
# scheduling.sh — Production Scheduling: work stations, shifts, work orders,
#                  assignments, daily goals, schedule calendar
# =============================================================================
set -euo pipefail
source "$HOME/.asdf/asdf.sh"
cd /home/ubuntu/shopfloor

mkdir -p app/policies app/views/work_stations app/views/shifts app/views/work_orders app/views/assignments app/views/daily_goals app/views/schedule

# ---- Policies ----
cat > app/policies/work_station_policy.rb << 'RUBY'
class WorkStationPolicy < ApplicationPolicy
  def index?   = user.scheduler? || user.operator? || user.admin?
  def show?    = index?
  def create?  = user.admin?
  def new?     = create?
  def update?  = user.scheduler? || user.admin?
  def edit?    = update?
  def destroy? = user.admin?
end
RUBY

cat > app/policies/shift_policy.rb << 'RUBY'
class ShiftPolicy < ApplicationPolicy
  def index?   = user.scheduler? || user.operator? || user.admin?
  def show?    = index?
  def create?  = user.scheduler? || user.admin?
  def new?     = create?
  def update?  = user.scheduler? || user.admin?
  def edit?    = update?
  def destroy? = user.scheduler? || user.admin?
end
RUBY

cat > app/policies/work_order_policy.rb << 'RUBY'
class WorkOrderPolicy < ApplicationPolicy
  def index?   = user.scheduler? || user.operator? || user.admin?
  def show?    = index?
  def create?  = user.scheduler? || user.admin?
  def new?     = create?
  def update?  = user.scheduler? || user.admin?
  def edit?    = update?
  def destroy? = user.admin?
end
RUBY

cat > app/policies/assignment_policy.rb << 'RUBY'
class AssignmentPolicy < ApplicationPolicy
  def index?    = user.scheduler? || user.operator? || user.admin?
  def show?     = index?
  def create?   = user.scheduler? || user.admin?
  def new?      = create?
  def update?   = user.scheduler? || user.admin?
  def edit?     = update?
  def destroy?  = user.scheduler? || user.admin?
  def start?    = (record.worker == user || user.admin?) && record.work_order.planned?
  def complete? = (record.worker == user || user.admin?) && record.work_order.in_progress?
end
RUBY

cat > app/policies/daily_goal_policy.rb << 'RUBY'
class DailyGoalPolicy < ApplicationPolicy
  def index?   = user.scheduler? || user.operator? || user.admin?
  def show?    = index?
  def create?  = user.scheduler? || user.admin?
  def new?     = create?
  def update?  = user.scheduler? || user.admin?
  def edit?    = update?
  def destroy? = user.admin?
end
RUBY

# ---- ScheduleController ----
cat > app/controllers/schedule_controller.rb << 'RUBY'
class ScheduleController < ApplicationController
  after_action :verify_authorized

  def index
    @date = params[:date]&.to_date || Date.current
    @shifts = policy_scope(Shift).where(date: @date.all_week).includes(:work_station, assignments: [:worker, :work_order])
    authorize :schedule, :index?
  end

  def my
    @assignments = current_user.assignments.includes(:shift, :work_order, :work_station).where(shifts: { date: Date.current.all_week })
    authorize :schedule, :my?
  end
end
RUBY

cat > app/policies/schedule_policy.rb << 'RUBY'
class SchedulePolicy < Struct.new(:user, :schedule)
  def index? = user.scheduler? || user.operator? || user.admin?
  def my?    = user.operator? || user.admin?
end
RUBY

# ---- Controllers ----
cat > app/controllers/work_stations_controller.rb << 'RUBY'
class WorkStationsController < ApplicationController
  before_action :set_work_station, only: %i[show edit update destroy]
  after_action :verify_authorized

  def index
    authorize WorkStation
    @work_stations = policy_scope(WorkStation).order(:name)
  end

  def show
    @shifts = @work_station.shifts.includes(:assignments).order(date: :desc).limit(20)
  end

  def new
    @work_station = WorkStation.new
    authorize @work_station
  end

  def edit
  end

  def create
    @work_station = WorkStation.new(work_station_params)
    authorize @work_station
    if @work_station.save
      redirect_to @work_station, notice: "Work station created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @work_station.update(work_station_params)
      redirect_to @work_station, notice: "Work station updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @work_station.destroy!
    redirect_to work_stations_path, notice: "Work station deleted."
  end

  private

  def set_work_station
    @work_station = WorkStation.find(params[:id])
    authorize @work_station
  end

  def work_station_params
    params.require(:work_station).permit(:name, :code, :department, :station_type, :description)
  end
end
RUBY

cat > app/controllers/shifts_controller.rb << 'RUBY'
class ShiftsController < ApplicationController
  before_action :set_shift, only: %i[show edit update destroy]
  after_action :verify_authorized

  def index
    authorize Shift
    @date = params[:date]&.to_date || Date.current
    @shifts = policy_scope(Shift).where(date: @date.all_week).includes(:work_station, assignments: [:worker, :work_order]).order(:date, :start_time)
  end

  def show
  end

  def new
    @shift = Shift.new
    authorize @shift
  end

  def edit
  end

  def create
    @shift = Shift.new(shift_params)
    authorize @shift
    if @shift.save
      redirect_to @shift, notice: "Shift created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @shift.update(shift_params)
      redirect_to @shift, notice: "Shift updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @shift.destroy!
    redirect_to shifts_path, notice: "Shift deleted."
  end

  private

  def set_shift
    @shift = Shift.find(params[:id])
    authorize @shift
  end

  def shift_params
    params.require(:shift).permit(:name, :date, :start_time, :end_time, :work_station_id)
  end
end
RUBY

cat > app/controllers/work_orders_controller.rb << 'RUBY'
class WorkOrdersController < ApplicationController
  before_action :set_work_order, only: %i[show edit update destroy]
  after_action :verify_authorized

  def index
    authorize WorkOrder
    @work_orders = policy_scope(WorkOrder).includes(:part).order(due_date: :asc)
    @work_orders = @work_orders.where(status: params[:status]) if params[:status].present?
  end

  def show
    @assignments = @work_order.assignments.includes(:worker, :work_station, :shift)
    @weigh_sessions = @work_order.weigh_sessions.includes(:worker, :weigh_station).limit(20)
  end

  def new
    @work_order = WorkOrder.new
    authorize @work_order
  end

  def edit
  end

  def create
    @work_order = WorkOrder.new(work_order_params)
    authorize @work_order
    if @work_order.save
      redirect_to @work_order, notice: "Work order created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @work_order.update(work_order_params)
      redirect_to @work_order, notice: "Work order updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @work_order.destroy!
    redirect_to work_orders_path, notice: "Work order deleted."
  end

  private

  def set_work_order
    @work_order = WorkOrder.find(params[:id])
    authorize @work_order
  end

  def work_order_params
    params.require(:work_order).permit(:order_number, :part_id, :quantity, :due_date, :status, :priority, :notes)
  end
end
RUBY

cat > app/controllers/assignments_controller.rb << 'RUBY'
class AssignmentsController < ApplicationController
  before_action :set_assignment, only: %i[show edit update destroy start complete]
  after_action :verify_authorized

  def index
    authorize Assignment
    @assignments = policy_scope(Assignment).includes(:shift, :work_order, :work_station, :worker).order(planned_start: :desc)
  end

  def show
  end

  def new
    @assignment = Assignment.new
    authorize @assignment
  end

  def edit
  end

  def create
    @assignment = Assignment.new(assignment_params)
    authorize @assignment
    if @assignment.save
      redirect_to @assignment, notice: "Assignment created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @assignment.update(assignment_params)
      redirect_to @assignment, notice: "Assignment updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @assignment.destroy!
    redirect_to assignments_path, notice: "Assignment deleted."
  end

  def start
    @assignment.work_order.update!(status: :in_progress)
    @assignment.update!(actual_start: Time.current)
    redirect_to @assignment, notice: "Assignment started."
  end

  def complete
    @assignment.work_order.update!(status: :completed)
    @assignment.update!(actual_end: Time.current)
    redirect_to @assignment, notice: "Assignment completed."
  end

  private

  def set_assignment
    @assignment = Assignment.find(params[:id])
    authorize @assignment
  end

  def assignment_params
    params.require(:assignment).permit(:shift_id, :work_order_id, :worker_id, :work_station_id, :planned_start, :planned_end, :notes)
  end
end
RUBY

cat > app/controllers/daily_goals_controller.rb << 'RUBY'
class DailyGoalsController < ApplicationController
  before_action :set_daily_goal, only: %i[show edit update destroy]
  after_action :verify_authorized

  def index
    authorize DailyGoal
    @date = params[:date]&.to_date || Date.current
    @daily_goals = policy_scope(DailyGoal).where(date: @date).includes(:work_station, :worker)
  end

  def show
  end

  def new
    @daily_goal = DailyGoal.new
    authorize @daily_goal
  end

  def edit
  end

  def create
    @daily_goal = DailyGoal.new(daily_goal_params)
    authorize @daily_goal
    if @daily_goal.save
      redirect_to daily_goals_path, notice: "Daily goal created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @daily_goal.update(daily_goal_params)
      redirect_to daily_goals_path, notice: "Daily goal updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @daily_goal.destroy!
    redirect_to daily_goals_path, notice: "Daily goal deleted."
  end

  private

  def set_daily_goal
    @daily_goal = DailyGoal.find(params[:id])
    authorize @daily_goal
  end

  def daily_goal_params
    params.require(:daily_goal).permit(:date, :work_station_id, :worker_id, :target_quantity, :unit, :achieved_quantity)
  end
end
RUBY

# ---- Schedule Views ----
cat > app/views/schedule/index.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Schedule</h1>
  <div class="flex gap-2">
    <%= link_to "◀ Prev", schedule_path(date: @date - 1.week), class: "btn btn-ghost btn-sm" %>
    <span class="btn btn-ghost btn-sm no-animation"><%= @date.strftime("%b %d, %Y") %></span>
    <%= link_to "Next ▶", schedule_path(date: @date + 1.week), class: "btn btn-ghost btn-sm" %>
  </div>
</div>

<% @shifts.group_by(&:date).sort.each do |date, shifts| %>
  <div class="card bg-base-200 mb-4">
    <div class="card-body">
      <h3 class="card-title text-sm"><%= l date, format: :long %></h3>
      <% shifts.each do |shift| %>
        <div class="border-t border-base-300 pt-2 mt-2">
          <div class="flex items-center justify-between">
            <div>
              <span class="font-medium"><%= link_to shift.name, shift, class: "link link-hover" %></span>
              <span class="text-sm text-base-content/60 ml-2"><%= shift.work_station&.name %></span>
              <span class="text-xs text-base-content/50 ml-2"><%= shift.start_time&.strftime("%H:%M") %>-<%= shift.end_time&.strftime("%H:%M") %></span>
            </div>
            <span class="badge badge-sm"><%= pluralize(shift.assignments.count, "assignment") %></span>
          </div>
          <% if shift.assignments.any? %>
            <div class="mt-1 space-y-1">
              <% shift.assignments.each do |a| %>
                <div class="text-sm flex items-center gap-2">
                  <span class="w-2 h-2 rounded-full <%= a.actual_start ? 'bg-success' : 'bg-base-300' %>"></span>
                  <%= link_to a.work_order&.order_number, a, class: "link link-hover" %>
                  <span class="text-base-content/50"><%= a.worker&.name %></span>
                  <span class="text-base-content/40 text-xs"><%= a.work_station&.name %></span>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
  </div>
<% end %>
<% if @shifts.empty? %>
  <div class="text-center py-12 text-base-content/50"><p>No shifts this week.</p></div>
<% end %>
ERB

cat > app/views/schedule/my.html.erb << 'ERB'
<div class="mb-6">
  <h1 class="text-2xl font-bold">My Schedule</h1>
</div>

<div class="space-y-4">
  <% @assignments.each do |a| %>
    <div class="card bg-base-200 border <%= a.actual_start ? 'border-success' : 'border-base-300' %>">
      <div class="card-body">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="card-title text-sm"><%= link_to a.work_order&.order_number, a, class: "link link-hover" %></h3>
            <p class="text-xs text-base-content/60"><%= a.work_station&.name %> &middot; <%= a.shift&.name %> &middot; <%= l a.planned_start, format: :short %>-<%= l a.planned_end, format: :short %></p>
          </div>
          <div class="flex gap-2">
            <% if policy(a).start? %>
              <%= button_to "Start", start_assignment_path(a), method: :post, class: "btn btn-success btn-sm" %>
            <% end %>
            <% if policy(a).complete? %>
              <%= button_to "Complete", complete_assignment_path(a), method: :post, class: "btn btn-primary btn-sm" %>
            <% end %>
          </div>
        </div>
      </div>
    </div>
  <% end %>
</div>
<% if @assignments.empty? %>
  <div class="text-center py-12 text-base-content/50"><p>No assignments this week.</p></div>
<% end %>
ERB

# ---- CRUD views ----
cat > app/views/work_stations/index.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Work Stations</h1>
  <% if policy(WorkStation).create? %><%= link_to "New Station", new_work_station_path, class: "btn btn-primary" %><% end %>
</div>
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
  <% @work_stations.each do |ws| %>
    <div class="card bg-base-200 border border-base-300">
      <div class="card-body">
        <h3 class="card-title"><%= link_to ws.name, ws, class: "link link-hover" %></h3>
        <p class="text-sm text-base-content/60"><%= ws.code %> &middot; <%= ws.station_type&.titleize %></p>
        <p class="text-sm text-base-content/50"><%= ws.department %></p>
      </div>
    </div>
  <% end %>
</div>
<% if @work_stations.empty? %><div class="text-center py-12 text-base-content/50"><p>No work stations.</p></div><% end %>
ERB

cat > app/views/work_stations/show.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold"><%= @work_station.name %></h1>
  <% if policy(@work_station).edit? %><%= link_to "Edit", edit_work_station_path(@work_station), class: "btn btn-outline btn-sm" %><% end %>
</div>
<div class="card bg-base-200 mb-6"><div class="card-body space-y-2 text-sm">
  <div class="flex justify-between"><span class="text-base-content/60">Code</span><span><%= @work_station.code %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Type</span><span><%= @work_station.station_type&.titleize %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Department</span><span><%= @work_station.department %></span></div>
</div></div>
<h3 class="text-lg font-semibold mb-3">Recent Shifts</h3>
<div class="space-y-2">
  <% @shifts.each do |s| %>
    <div class="card bg-base-200"><div class="card-body py-3"><%= link_to "#{s.name} (#{l s.date})", s, class: "link link-hover" %></div></div>
  <% end %>
</div>
ERB

WORKSTATION_FORM='<%= form_with(model: @work_station, local: true) do |f| %>
  <div class="form-control"><%= f.label :name, class: "label" %><%= f.text_field :name, class: "input input-bordered w-full", required: true %></div>
  <div class="form-control"><%= f.label :code, class: "label" %><%= f.text_field :code, class: "input input-bordered w-full" %></div>
  <div class="form-control"><%= f.label :station_type, class: "label" %><%= f.select :station_type, WorkStation.station_types.keys.map { |r| [r.titleize, r] }, {}, class: "select select-bordered w-full" %></div>
  <div class="form-control"><%= f.label :department, class: "label" %><%= f.text_field :department, class: "input input-bordered w-full" %></div>
  <div class="form-control"><%= f.label :description, class: "label" %><%= f.text_area :description, rows: 3, class: "textarea textarea-bordered w-full" %></div>
  <div class="flex gap-3 pt-2"><%= f.submit class: "btn btn-primary" %><%= link_to "Cancel", work_station.persisted? ? work_station : work_stations_path, class: "btn btn-ghost" %></div>
<% end %>'

cat > app/views/work_stations/new.html.erb << ERB
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">New Work Station</h1>$WORKSTATION_FORM</div>
ERB

cat > app/views/work_stations/edit.html.erb << ERB
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">Edit Work Station</h1>$WORKSTATION_FORM</div>
ERB

# Shift views
SHIFT_FORM='<%= form_with(model: @shift, local: true) do |f| %>
  <div class="form-control"><%= f.label :name, class: "label" %><%= f.text_field :name, class: "input input-bordered w-full" %></div>
  <div class="grid grid-cols-2 gap-4">
    <div class="form-control"><%= f.label :date, class: "label" %><%= f.date_field :date, class: "input input-bordered w-full" %></div>
    <div class="form-control"><%= f.label :work_station_id, class: "label" %><%= f.collection_select :work_station_id, WorkStation.order(:name), :id, :name, { include_blank: true }, class: "select select-bordered w-full" %></div>
  </div>
  <div class="grid grid-cols-2 gap-4">
    <div class="form-control"><%= f.label :start_time, class: "label" %><%= f.time_field :start_time, class: "input input-bordered w-full" %></div>
    <div class="form-control"><%= f.label :end_time, class: "label" %><%= f.time_field :end_time, class: "input input-bordered w-full" %></div>
  </div>
  <div class="flex gap-3 pt-2"><%= f.submit class: "btn btn-primary" %><%= link_to "Cancel", shift.persisted? ? shift : shifts_path, class: "btn btn-ghost" %></div>
<% end %>'

cat > app/views/shifts/index.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Shifts</h1>
  <% if policy(Shift).create? %><%= link_to "New Shift", new_shift_path, class: "btn btn-primary" %><% end %>
</div>
<div class="space-y-3">
  <% @shifts.each do |s| %>
    <div class="card bg-base-200"><div class="card-body py-3 flex-row items-center justify-between">
      <div><span class="font-medium"><%= link_to s.name, s, class: "link link-hover" %></span><span class="text-sm text-base-content/60 ml-3"><%= l s.date %> &middot; <%= s.work_station&.name %></span></div>
      <span class="badge badge-sm"><%= pluralize(s.assignments.count, "assignment") %></span>
    </div></div>
  <% end %>
</div>
<% if @shifts.empty? %><div class="text-center py-12 text-base-content/50"><p>No shifts.</p></div><% end %>
ERB

cat > app/views/shifts/show.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold"><%= @shift.name %></h1>
  <% if policy(@shift).edit? %><%= link_to "Edit", edit_shift_path(@shift), class: "btn btn-outline btn-sm" %><% end %>
</div>
<div class="card bg-base-200 mb-6"><div class="card-body space-y-2 text-sm">
  <div class="flex justify-between"><span class="text-base-content/60">Date</span><span><%= l @shift.date %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Time</span><span><%= @shift.start_time&.strftime("%H:%M") %> — <%= @shift.end_time&.strftime("%H:%M") %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Station</span><span><%= @shift.work_station&.name %></span></div>
</div></div>
<h3 class="text-lg font-semibold mb-3">Assignments</h3>
<div class="space-y-2">
  <% @shift.assignments.each do |a| %>
    <div class="card bg-base-200"><div class="card-body py-3"><%= link_to a.work_order&.order_number || "Assignment ##{a.id}", a, class: "link link-hover" %> &middot; <%= a.worker&.name %></div></div>
  <% end %>
</div>
ERB

cat > app/views/shifts/new.html.erb << ERB
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">New Shift</h1>$SHIFT_FORM</div>
ERB

cat > app/views/shifts/edit.html.erb << ERB
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">Edit Shift</h1>$SHIFT_FORM</div>
ERB

# Work Order views
cat > app/views/work_orders/index.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Work Orders</h1>
  <% if policy(WorkOrder).create? %><%= link_to "New Work Order", new_work_order_path, class: "btn btn-primary" %><% end %>
</div>
<div class="flex gap-2 mb-6 flex-wrap">
  <% %w[planned in_progress completed cancelled].each do |s| %>
    <%= link_to s.titleize, work_orders_path(status: s), class: "btn btn-sm #{params[:status] == s ? 'btn-primary' : 'btn-ghost'}" %>
  <% end %>
  <%= link_to "All", work_orders_path, class: "btn btn-sm #{params[:status].blank? ? 'btn-primary' : 'btn-ghost'}" %>
</div>
<div class="overflow-x-auto">
  <table class="table table-zebra">
    <thead><tr><th>Order #</th><th>Part</th><th>Qty</th><th>Due</th><th>Status</th><th>Priority</th><th></th></tr></thead>
    <tbody>
      <% @work_orders.each do |wo| %>
        <tr>
          <td class="font-medium"><%= link_to wo.order_number, wo, class: "link link-hover" %></td>
          <td><%= wo.part&.name %></td>
          <td><%= wo.quantity %></td>
          <td class="text-sm"><%= l wo.due_date if wo.due_date %></td>
          <td><%= status_badge(wo.status) %></td>
          <td><%= wo.priority&.titleize %></td>
          <td><%= link_to "View", wo, class: "btn btn-ghost btn-xs" %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
<% if @work_orders.empty? %><div class="text-center py-12 text-base-content/50"><p>No work orders.</p></div><% end %>
ERB

cat > app/views/work_orders/show.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <div><h1 class="text-2xl font-bold"><%= @work_order.order_number %></h1><p class="text-base-content/60"><%= @work_order.part&.name %></p></div>
  <div class="flex gap-2">
    <%= status_badge(@work_order.status) %>
    <% if policy(@work_order).edit? %><%= link_to "Edit", edit_work_order_path(@work_order), class: "btn btn-outline btn-sm" %><% end %>
  </div>
</div>
<div class="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-6">
  <div class="card bg-base-200"><div class="card-body space-y-2 text-sm">
    <div class="flex justify-between"><span class="text-base-content/60">Quantity</span><span><%= @work_order.quantity %></span></div>
    <div class="flex justify-between"><span class="text-base-content/60">Due Date</span><span><%= l @work_order.due_date if @work_order.due_date %></span></div>
    <div class="flex justify-between"><span class="text-base-content/60">Priority</span><span><%= @work_order.priority&.titleize %></span></div>
  </div></div>
  <div class="card bg-base-200"><div class="card-body"><h3 class="card-title text-sm">Notes</h3><p class="text-sm text-base-content/60"><%= @work_order.notes.presence || "None" %></p></div></div>
</div>
<div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
  <div><h3 class="text-lg font-semibold mb-3">Assignments</h3><div class="space-y-2">
    <% @assignments.each do |a| %><div class="card bg-base-200"><div class="card-body py-3"><%= link_to "Assignment ##{a.id}", a, class: "link link-hover" %> &middot; <%= a.worker&.name %></div></div><% end %>
    <% if @assignments.empty? %><p class="text-sm text-base-content/50">None</p><% end %>
  </div></div>
  <div><h3 class="text-lg font-semibold mb-3">Weigh Sessions</h3><div class="space-y-2">
    <% @weigh_sessions.each do |ws| %><div class="card bg-base-200"><div class="card-body py-3"><%= ws.weight_value %> <%= ws.unit %> &middot; <%= ws.worker&.name %></div></div><% end %>
    <% if @weigh_sessions.empty? %><p class="text-sm text-base-content/50">None</p><% end %>
  </div></div>
</div>
ERB

WORK_ORDER_FORM='<%= form_with(model: @work_order, local: true) do |f| %>
  <div class="form-control"><%= f.label :order_number, class: "label" %><%= f.text_field :order_number, class: "input input-bordered w-full" %></div>
  <div class="grid grid-cols-2 gap-4">
    <div class="form-control"><%= f.label :part_id, class: "label" %><%= f.collection_select :part_id, Part.order(:name), :id, :name, { include_blank: true }, class: "select select-bordered w-full" %></div>
    <div class="form-control"><%= f.label :quantity, class: "label" %><%= f.number_field :quantity, class: "input input-bordered w-full" %></div>
  </div>
  <div class="grid grid-cols-2 gap-4">
    <div class="form-control"><%= f.label :due_date, class: "label" %><%= f.date_field :due_date, class: "input input-bordered w-full" %></div>
    <div class="form-control"><%= f.label :priority, class: "label" %><%= f.select :priority, WorkOrder.priorities.keys.map { |p| [p.titleize, p] }, {}, class: "select select-bordered w-full" %></div>
  </div>
  <div class="form-control"><%= f.label :notes, class: "label" %><%= f.text_area :notes, rows: 3, class: "textarea textarea-bordered w-full" %></div>
  <div class="flex gap-3 pt-2"><%= f.submit class: "btn btn-primary" %><%= link_to "Cancel", work_order.persisted? ? work_order : work_orders_path, class: "btn btn-ghost" %></div>
<% end %>'

cat > app/views/work_orders/new.html.erb << ERB
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">New Work Order</h1>$WORK_ORDER_FORM</div>
ERB

cat > app/views/work_orders/edit.html.erb << ERB
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">Edit Work Order</h1>$WORK_ORDER_FORM</div>
ERB

# Assignment views
cat > app/views/assignments/index.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Assignments</h1>
  <% if policy(Assignment).create? %><%= link_to "New Assignment", new_assignment_path, class: "btn btn-primary" %><% end %>
</div>
<div class="overflow-x-auto">
  <table class="table table-zebra">
    <thead><tr><th>Work Order</th><th>Worker</th><th>Station</th><th>Shift</th><th>Planned</th><th>Status</th><th></th></tr></thead>
    <tbody>
      <% @assignments.each do |a| %>
        <tr>
          <td><%= link_to a.work_order&.order_number, a, class: "link link-hover font-medium" %></td>
          <td><%= a.worker&.name %></td>
          <td><%= a.work_station&.name %></td>
          <td><%= a.shift&.name %></td>
          <td class="text-sm"><%= l a.planned_start, format: :short %>-<%= l a.planned_end, format: :short %></td>
          <td><%= a.actual_start ? (a.actual_end ? "Completed" : "In Progress") : "Planned" %></td>
          <td><%= link_to "View", a, class: "btn btn-ghost btn-xs" %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
<% if @assignments.empty? %><div class="text-center py-12 text-base-content/50"><p>No assignments.</p></div><% end %>
ERB

cat > app/views/assignments/show.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Assignment: <%= @assignment.work_order&.order_number %></h1>
  <div class="flex gap-2">
    <% if policy(@assignment).start? %><%= button_to "Start", start_assignment_path(@assignment), method: :post, class: "btn btn-success btn-sm" %><% end %>
    <% if policy(@assignment).complete? %><%= button_to "Complete", complete_assignment_path(@assignment), method: :post, class: "btn btn-primary btn-sm" %><% end %>
    <% if policy(@assignment).edit? %><%= link_to "Edit", edit_assignment_path(@assignment), class: "btn btn-outline btn-sm" %><% end %>
  </div>
</div>
<div class="card bg-base-200"><div class="card-body space-y-2 text-sm">
  <div class="flex justify-between"><span class="text-base-content/60">Work Order</span><span><%= link_to @assignment.work_order&.order_number, @assignment.work_order, class: "link link-hover" %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Worker</span><span><%= @assignment.worker&.name %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Station</span><span><%= @assignment.work_station&.name %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Shift</span><span><%= @assignment.shift&.name %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Planned</span><span><%= l @assignment.planned_start, format: :long %> — <%= l @assignment.planned_end, format: :long %></span></div>
  <% if @assignment.actual_start %><div class="flex justify-between"><span class="text-base-content/60">Actual Start</span><span><%= l @assignment.actual_start, format: :long %></span></div><% end %>
  <% if @assignment.actual_end %><div class="flex justify-between"><span class="text-base-content/60">Actual End</span><span><%= l @assignment.actual_end, format: :long %></span></div><% end %>
</div></div>
ERB

ASSIGNMENT_FORM='<%= form_with(model: @assignment, local: true) do |f| %>
  <div class="grid grid-cols-2 gap-4">
    <div class="form-control"><%= f.label :work_order_id, class: "label" %><%= f.collection_select :work_order_id, WorkOrder.order(:order_number), :id, :order_number, { include_blank: true }, class: "select select-bordered w-full" %></div>
    <div class="form-control"><%= f.label :worker_id, class: "label" %><%= f.collection_select :worker_id, User.active.order(:name), :id, :name, { include_blank: true }, class: "select select-bordered w-full" %></div>
  </div>
  <div class="grid grid-cols-2 gap-4">
    <div class="form-control"><%= f.label :shift_id, class: "label" %><%= f.collection_select :shift_id, Shift.order(:date), :id, :name, { include_blank: true }, class: "select select-bordered w-full" %></div>
    <div class="form-control"><%= f.label :work_station_id, class: "label" %><%= f.collection_select :work_station_id, WorkStation.order(:name), :id, :name, { include_blank: true }, class: "select select-bordered w-full" %></div>
  </div>
  <div class="grid grid-cols-2 gap-4">
    <div class="form-control"><%= f.label :planned_start, class: "label" %><%= f.datetime_field :planned_start, class: "input input-bordered w-full" %></div>
    <div class="form-control"><%= f.label :planned_end, class: "label" %><%= f.datetime_field :planned_end, class: "input input-bordered w-full" %></div>
  </div>
  <div class="form-control"><%= f.label :notes, class: "label" %><%= f.text_area :notes, rows: 3, class: "textarea textarea-bordered w-full" %></div>
  <div class="flex gap-3 pt-2"><%= f.submit class: "btn btn-primary" %><%= link_to "Cancel", assignment.persisted? ? assignment : assignments_path, class: "btn btn-ghost" %></div>
<% end %>'

cat > app/views/assignments/new.html.erb << ERB
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">New Assignment</h1>$ASSIGNMENT_FORM</div>
ERB

cat > app/views/assignments/edit.html.erb << ERB
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">Edit Assignment</h1>$ASSIGNMENT_FORM</div>
ERB

# Daily Goal views
cat > app/views/daily_goals/index.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Daily Goals</h1>
  <div class="flex gap-2">
    <%= link_to "◀", daily_goals_path(date: @date - 1.day), class: "btn btn-ghost btn-sm" %>
    <span class="btn btn-ghost btn-sm no-animation"><%= l @date %></span>
    <%= link_to "▶", daily_goals_path(date: @date + 1.day), class: "btn btn-ghost btn-sm" %>
    <% if policy(DailyGoal).create? %><%= link_to "New Goal", new_daily_goal_path, class: "btn btn-primary btn-sm" %><% end %>
  </div>
</div>
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
  <% @daily_goals.each do |dg| %>
    <div class="card bg-base-200 border border-base-300">
      <div class="card-body">
        <h3 class="card-title text-sm"><%= dg.work_station&.name %></h3>
        <div class="flex items-center gap-2">
          <div class="radial-progress text-primary" style="--value:<%= dg.achieved_quantity.to_f / dg.target_quantity * 100 %>"><%= (dg.achieved_quantity.to_f / dg.target_quantity * 100).round %>%</div>
          <div class="text-sm"><%= dg.achieved_quantity %> / <%= dg.target_quantity %> <%= dg.unit %></div>
        </div>
        <p class="text-xs text-base-content/60"><%= dg.worker&.name %></p>
      </div>
    </div>
  <% end %>
</div>
<% if @daily_goals.empty? %><div class="text-center py-12 text-base-content/50"><p>No goals for this date.</p></div><% end %>
ERB

DAILY_GOAL_FORM='<%= form_with(model: @daily_goal, local: true) do |f| %>
  <div class="form-control"><%= f.label :date, class: "label" %><%= f.date_field :date, class: "input input-bordered w-full" %></div>
  <div class="grid grid-cols-2 gap-4">
    <div class="form-control"><%= f.label :work_station_id, class: "label" %><%= f.collection_select :work_station_id, WorkStation.order(:name), :id, :name, { include_blank: true }, class: "select select-bordered w-full" %></div>
    <div class="form-control"><%= f.label :worker_id, class: "label" %><%= f.collection_select :worker_id, User.active.order(:name), :id, :name, { include_blank: true }, class: "select select-bordered w-full" %></div>
  </div>
  <div class="grid grid-cols-2 gap-4">
    <div class="form-control"><%= f.label :target_quantity, class: "label" %><%= f.number_field :target_quantity, class: "input input-bordered w-full" %></div>
    <div class="form-control"><%= f.label :unit, class: "label" %><%= f.text_field :unit, class: "input input-bordered w-full" %></div>
  </div>
  <div class="form-control"><%= f.label :achieved_quantity, class: "label" %><%= f.number_field :achieved_quantity, class: "input input-bordered w-full" %></div>
  <div class="flex gap-3 pt-2"><%= f.submit class: "btn btn-primary" %><%= link_to "Cancel", daily_goals_path, class: "btn btn-ghost" %></div>
<% end %>'

cat > app/views/daily_goals/new.html.erb << ERB
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">New Daily Goal</h1>$DAILY_GOAL_FORM</div>
ERB

cat > app/views/daily_goals/edit.html.erb << ERB
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">Edit Daily Goal</h1>$DAILY_GOAL_FORM</div>
ERB

echo "=== Scheduling bootstrap complete ==="
