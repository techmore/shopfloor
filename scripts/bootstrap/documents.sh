#!/bin/bash
# =============================================================================
# documents.sh — Document Management: controllers, views, policies, helpers
# =============================================================================
set -euo pipefail
source "$HOME/.asdf/asdf.sh"
cd /home/ubuntu/shopfloor

mkdir -p app/views/documents app/views/categories app/policies app/helpers

# ---- Document Policy ----
cat > app/policies/document_policy.rb << 'RUBY'
class DocumentPolicy < ApplicationPolicy
  def index?   = user.viewer? || user.author? || user.reviewer? || user.approver? || user.admin?
  def show?    = index?
  def create?  = user.author? || user.admin?
  def new?     = create?
  def update?  = (record.author == user || user.admin?) && record.draft?
  def edit?    = update?
  def destroy? = user.admin? && record.draft?

  def submit?   = (record.author == user || user.admin?) && record.draft?
  def approve?  = (user.approver? || user.admin?) && record.review?
  def reject?   = (user.approver? || user.admin?) && record.review?
  def publish?  = (user.approver? || user.admin?) && record.approved?
  def archive?  = user.admin? && (record.published? || record.approved?)
end
RUBY

# ---- Category Policy ----
cat > app/policies/category_policy.rb << 'RUBY'
class CategoryPolicy < ApplicationPolicy
  def index?   = user.viewer? || user.author? || user.reviewer? || user.approver? || user.admin?
  def show?    = index?
  def create?  = user.admin?
  def new?     = create?
  def update?  = user.admin?
  def edit?    = update?
  def destroy? = user.admin?
end
RUBY

# ---- DocumentsController ----
cat > app/controllers/documents_controller.rb << 'RUBY'
class DocumentsController < ApplicationController
  before_action :set_document, only: %i[show edit update destroy submit approve reject publish archive versions qr_code diff]
  after_action :verify_authorized

  def index
    @documents = policy_scope(Document).includes(:category, :author).order(updated_at: :desc)
    @documents = @documents.where(status: params[:status]) if params[:status].present?
    @documents = @documents.where(category_id: params[:category_id]) if params[:category_id].present?
  end

  def show
  end

  def new
    @document = Document.new
    authorize @document
  end

  def edit
  end

  def create
    @document = Document.new(document_params)
    @document.author = current_user
    authorize @document

    if @document.save
      redirect_to @document, notice: "Document created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @document.update(document_params)
      redirect_to @document, notice: "Document updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @document.destroy!
    redirect_to documents_path, notice: "Document deleted."
  end

  # ---- Workflow ----
  def submit
    if @document.update(status: :review)
      @document.approvals.create!(approver: nil, decision: :pending, document_version: (@document.version || 1))
      redirect_to @document, notice: "Document submitted for review."
    else
      redirect_to @document, alert: "Could not submit."
    end
  end

  def approve
    ActiveRecord::Base.transaction do
      @document.approvals.pending.find_each do |a|
        a.update!(decision: :approved, approver: current_user, signed_at: Time.current)
      end
      @document.update!(status: :approved)
    end
    redirect_to @document, notice: "Document approved."
  end

  def reject
    ActiveRecord::Base.transaction do
      @document.approvals.pending.find_each do |a|
        a.update!(decision: :rejected, approver: current_user, signed_at: Time.current)
      end
      @document.update!(status: :draft)
    end
    redirect_to @document, alert: "Document rejected, returned to draft."
  end

  def publish
    @document.update!(status: :published, version: (@document.version || 0) + 1)
    redirect_to @document, notice: "Document published."
  end

  def archive
    @document.update!(status: :archived)
    redirect_to @document, notice: "Document archived."
  end

  # ---- Extras ----
  def versions
  end

  def qr_code
    redirect_to @document.qr_code_url if @document.qr_code.present?
  end

  def diff
  end

  private

  def set_document
    @document = Document.find(params[:id])
    authorize @document
  end

  def document_params
    params.require(:document).permit(:title, :slug, :category_id, :status, :standard_ref, :document_number, :body)
  end
end
RUBY

# ---- CategoriesController ----
cat > app/controllers/categories_controller.rb << 'RUBY'
class CategoriesController < ApplicationController
  before_action :set_category, only: %i[show edit update destroy]
  after_action :verify_authorized

  def index
    @categories = policy_scope(Category).order(:name)
  end

  def show
    @documents = @category.documents.includes(:author).order(updated_at: :desc)
  end

  def new
    @category = Category.new
    authorize @category
  end

  def edit
  end

  def create
    @category = Category.new(category_params)
    authorize @category
    if @category.save
      redirect_to @category, notice: "Category created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @category.update(category_params)
      redirect_to @category, notice: "Category updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy!
    redirect_to categories_path, notice: "Category deleted."
  end

  private

  def set_category
    @category = Category.find(params[:id])
    authorize @category
  end

  def category_params
    params.require(:category).permit(:name, :slug, :parent_id)
  end
end
RUBY

# ---- Document views ----

cat > app/views/documents/index.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <div>
    <h1 class="text-2xl font-bold">Documents</h1>
    <p class="text-base-content/70 mt-1"><%= @documents.count %> documents</p>
  </div>
  <div class="flex items-center gap-3">
    <% if policy(Document).create? %>
      <%= link_to "New Document", new_document_path, class: "btn btn-primary" %>
    <% end %>
  </div>
</div>

<div class="flex gap-2 mb-6 flex-wrap">
  <% %w[draft review approved published archived].each do |s| %>
    <%= link_to s.titleize, documents_path(status: s),
        class: "btn btn-sm #{params[:status] == s ? 'btn-primary' : 'btn-ghost'}" %>
  <% end %>
  <%= link_to "All", documents_path, class: "btn btn-sm #{params[:status].blank? ? 'btn-primary' : 'btn-ghost'}" %>
</div>

<div class="overflow-x-auto">
  <table class="table table-zebra">
    <thead>
      <tr>
        <th>Title</th>
        <th>Document #</th>
        <th>Category</th>
        <th>Status</th>
        <th>Version</th>
        <th>Author</th>
        <th>Updated</th>
        <th></th>
      </tr>
    </thead>
    <tbody>
      <% @documents.each do |doc| %>
        <tr>
          <td class="font-medium"><%= link_to doc.title, doc, class: "link link-hover" %></td>
          <td><%= doc.document_number %></td>
          <td><%= doc.category&.name %></td>
          <td><%= status_badge(doc.status) %></td>
          <td><%= doc.version || 1 %></td>
          <td><%= doc.author&.name %></td>
          <td class="text-sm text-base-content/60"><%= time_ago_in_words(doc.updated_at) %> ago</td>
          <td>
            <% if policy(doc).edit? %>
              <%= link_to "Edit", edit_document_path(doc), class: "btn btn-ghost btn-xs" %>
            <% end %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
<% if @documents.empty? %>
  <div class="text-center py-12 text-base-content/50">
    <p>No documents found.</p>
  </div>
<% end %>
ERB

cat > app/views/documents/show.html.erb << 'ERB'
<div class="mb-6">
  <div class="flex items-center justify-between">
    <div>
      <div class="flex items-center gap-3 mb-1">
        <h1 class="text-2xl font-bold"><%= @document.title %></h1>
        <%= status_badge(@document.status) %>
      </div>
      <p class="text-base-content/60 text-sm">
        <%= @document.document_number %> &middot; v<%= @document.version || 1 %>
        &middot; <%= @document.category&.name %>
        &middot; by <%= @document.author&.name %>
      </p>
    </div>
    <div class="flex items-center gap-2">
      <% if policy(@document).edit? %>
        <%= link_to "Edit", edit_document_path(@document), class: "btn btn-outline btn-sm" %>
      <% end %>
      <% if @document.draft? && policy(@document).submit? %>
        <%= button_to "Submit for Review", submit_document_path(@document), method: :post, class: "btn btn-primary btn-sm" %>
      <% end %>
      <% if @document.review? && policy(@document).approve? %>
        <%= button_to "Approve", approve_document_path(@document), method: :post, class: "btn btn-success btn-sm" %>
        <%= button_to "Reject", reject_document_path(@document), method: :post, class: "btn btn-error btn-sm" %>
      <% end %>
      <% if @document.approved? && policy(@document).publish? %>
        <%= button_to "Publish", publish_document_path(@document), method: :post, class: "btn btn-primary btn-sm" %>
      <% end %>
      <% if policy(@document).archive? %>
        <%= button_to "Archive", archive_document_path(@document), method: :post, class: "btn btn-ghost btn-sm" %>
      <% end %>
      <% if policy(@document).destroy? %>
        <%= button_to "Delete", @document, method: :delete, class: "btn btn-ghost btn-sm text-error", data: { turbo_confirm: "Delete this document?" } %>
      <% end %>
    </div>
  </div>
  <% if @document.standard_ref.present? %>
    <div class="badge badge-outline mt-2">Standard: <%= @document.standard_ref %></div>
  <% end %>
</div>

<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
  <div class="lg:col-span-2">
    <div class="card bg-base-200">
      <div class="card-body">
        <% if @document.respond_to?(:body) && @document.body.present? %>
          <div class="prose max-w-none"><%= simple_format(@document.body) %></div>
        <% else %>
          <p class="text-base-content/50 italic">No content yet.</p>
        <% end %>
      </div>
    </div>
  </div>

  <div class="space-y-4">
    <div class="card bg-base-200">
      <div class="card-body">
        <h3 class="card-title text-sm">Details</h3>
        <dl class="space-y-2 text-sm">
          <div class="flex justify-between"><dt class="text-base-content/60">Status</dt><dd><%= @document.status&.titleize %></dd></div>
          <div class="flex justify-between"><dt class="text-base-content/60">Version</dt><dd><%= @document.version || 1 %></dd></div>
          <div class="flex justify-between"><dt class="text-base-content/60">Author</dt><dd><%= @document.author&.name %></dd></div>
          <div class="flex justify-between"><dt class="text-base-content/60">Created</dt><dd><%= l @document.created_at.to_date, format: :default %></dd></div>
          <div class="flex justify-between"><dt class="text-base-content/60">Updated</dt><dd><%= time_ago_in_words(@document.updated_at) %> ago</dd></div>
        </dl>
      </div>
    </div>

    <% if @document.approvals.any? %>
      <div class="card bg-base-200">
        <div class="card-body">
          <h3 class="card-title text-sm">Approvals</h3>
          <div class="space-y-2">
            <% @document.approvals.each do |a| %>
              <div class="flex items-center justify-between text-sm">
                <span><%= a.approver&.name || "—" %></span>
                <%= approval_badge(a.decision) %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>

    <div class="card bg-base-200">
      <div class="card-body">
        <h3 class="card-title text-sm">Links</h3>
        <div class="flex flex-col gap-1 text-sm">
          <%= link_to "View Versions", document_versions_path(@document), class: "link link-hover" %>
          <%= link_to "View Diff", document_diff_path(@document), class: "link link-hover" %>
        </div>
      </div>
    </div>
  </div>
</div>
ERB

cat > app/views/documents/new.html.erb << 'ERB'
<div class="max-w-2xl mx-auto">
  <h1 class="text-2xl font-bold mb-6">New Document</h1>
  <%= render "form", document: @document %>
</div>
ERB

cat > app/views/documents/edit.html.erb << 'ERB'
<div class="max-w-2xl mx-auto">
  <h1 class="text-2xl font-bold mb-6">Edit Document</h1>
  <%= render "form", document: @document %>
</div>
ERB

cat > app/views/documents/_form.html.erb << 'ERB'
<%= form_with(model: document, local: true, class: "space-y-4") do |f| %>
  <% if document.errors.any? %>
    <div class="alert alert-error">
      <ul>
        <% document.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="form-control">
    <%= f.label :title, class: "label" %>
    <%= f.text_field :title, class: "input input-bordered w-full", required: true %>
  </div>

  <div class="form-control">
    <%= f.label :slug, class: "label" %>
    <%= f.text_field :slug, class: "input input-bordered w-full" %>
  </div>

  <div class="grid grid-cols-2 gap-4">
    <div class="form-control">
      <%= f.label :category_id, class: "label" %>
      <%= f.collection_select :category_id, Category.order(:name), :id, :name, { include_blank: true }, class: "select select-bordered w-full" %>
    </div>
    <div class="form-control">
      <%= f.label :document_number, class: "label" %>
      <%= f.text_field :document_number, class: "input input-bordered w-full" %>
    </div>
  </div>

  <div class="form-control">
    <%= f.label :standard_ref, class: "label" %>
    <%= f.text_field :standard_ref, class: "input input-bordered w-full", placeholder: "e.g. ISO 9001:2025" %>
  </div>

  <div class="form-control">
    <%= f.label :body, class: "label" %>
    <%= f.text_area :body, rows: 20, class: "textarea textarea-bordered w-full font-mono text-sm" %>
  </div>

  <div class="flex items-center gap-3 pt-2">
    <%= f.submit class: "btn btn-primary" %>
    <%= link_to "Cancel", document.persisted? ? document : documents_path, class: "btn btn-ghost" %>
  </div>
<% end %>
ERB

# ---- Category views ----

cat > app/views/categories/index.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Categories</h1>
  <% if policy(Category).create? %>
    <%= link_to "New Category", new_category_path, class: "btn btn-primary" %>
  <% end %>
</div>

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
  <% @categories.each do |cat| %>
    <div class="card bg-base-200 border border-base-300">
      <div class="card-body">
        <h3 class="card-title"><%= link_to cat.name, cat, class: "link link-hover" %></h3>
        <% if cat.documents.any? %>
          <p class="text-sm text-base-content/60"><%= pluralize(cat.documents.count, "document") %></p>
        <% end %>
        <div class="card-actions justify-end mt-2">
          <% if policy(cat).edit? %>
            <%= link_to "Edit", edit_category_path(cat), class: "btn btn-ghost btn-xs" %>
          <% end %>
        </div>
      </div>
    </div>
  <% end %>
</div>
<% if @categories.empty? %>
  <div class="text-center py-12 text-base-content/50">
    <p>No categories yet.</p>
  </div>
<% end %>
ERB

cat > app/views/categories/show.html.erb << 'ERB'
<div class="mb-6">
  <div class="flex items-center justify-between">
    <h1 class="text-2xl font-bold"><%= @category.name %></h1>
    <% if policy(@category).edit? %>
      <%= link_to "Edit", edit_category_path(@category), class: "btn btn-outline btn-sm" %>
    <% end %>
  </div>
  <% if @category.parent %>
    <p class="text-sm text-base-content/60 mt-1">Parent: <%= link_to @category.parent.name, @category.parent, class: "link link-hover" %></p>
  <% end %>
  <p class="text-sm text-base-content/60"><%= pluralize(@documents.count, "document") %></p>
</div>

<div class="overflow-x-auto">
  <table class="table table-zebra">
    <thead>
      <tr>
        <th>Title</th>
        <th>Document #</th>
        <th>Status</th>
        <th>Version</th>
        <th>Author</th>
        <th></th>
      </tr>
    </thead>
    <tbody>
      <% @documents.each do |doc| %>
        <tr>
          <td><%= link_to doc.title, doc, class: "link link-hover font-medium" %></td>
          <td><%= doc.document_number %></td>
          <td><%= status_badge(doc.status) %></td>
          <td><%= doc.version || 1 %></td>
          <td><%= doc.author&.name %></td>
          <td><%= link_to "View", doc, class: "btn btn-ghost btn-xs" %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
<% if @documents.empty? %>
  <div class="text-center py-12 text-base-content/50">
    <p>No documents in this category.</p>
  </div>
<% end %>
ERB

cat > app/views/categories/new.html.erb << 'ERB'
<div class="max-w-lg mx-auto">
  <h1 class="text-2xl font-bold mb-6">New Category</h1>
  <%= render "form", category: @category %>
</div>
ERB

cat > app/views/categories/edit.html.erb << 'ERB'
<div class="max-w-lg mx-auto">
  <h1 class="text-2xl font-bold mb-6">Edit Category</h1>
  <%= render "form", category: @category %>
</div>
ERB

cat > app/views/categories/_form.html.erb << 'ERB'
<%= form_with(model: category, local: true, class: "space-y-4") do |f| %>
  <% if category.errors.any? %>
    <div class="alert alert-error">
      <ul>
        <% category.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="form-control">
    <%= f.label :name, class: "label" %>
    <%= f.text_field :name, class: "input input-bordered w-full", required: true %>
  </div>

  <div class="form-control">
    <%= f.label :slug, class: "label" %>
    <%= f.text_field :slug, class: "input input-bordered w-full" %>
  </div>

  <div class="form-control">
    <%= f.label :parent_id, class: "label" %>
    <%= f.collection_select :parent_id, Category.order(:name), :id, :name, { include_blank: true }, class: "select select-bordered w-full" %>
  </div>

  <div class="flex items-center gap-3 pt-2">
    <%= f.submit class: "btn btn-primary" %>
    <%= link_to "Cancel", category.persisted? ? category : categories_path, class: "btn btn-ghost" %>
  </div>
<% end %>
ERB

# ---- Document versions view ----
cat > app/views/documents/versions.html.erb << 'ERB'
<div class="mb-6">
  <h1 class="text-2xl font-bold">Versions: <%= @document.title %></h1>
  <p class="text-base-content/60 mt-1"><%= link_to "Back to document", @document, class: "link link-hover" %></p>
</div>

<div class="overflow-x-auto">
  <table class="table table-zebra">
    <thead>
      <tr>
        <th>Version</th>
        <th>Event</th>
        <th>Modified by</th>
        <th>Date</th>
        <th></th>
      </tr>
    </thead>
    <tbody>
      <% @document.versions.reverse_each do |v| %>
        <tr>
          <td><%= v.index + 1 %></td>
          <td><%= v.event.titleize %></td>
          <td><%= User.find_by(id: v.whodunnit)&.name || "Unknown" %></td>
          <td class="text-sm"><%= l v.created_at, format: :long %></td>
          <td><%= link_to "View changes", document_diff_path(@document, version: v.id), class: "link link-xs" %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
<% if @document.versions.empty? %>
  <div class="text-center py-12 text-base-content/50">
    <p>No version history yet.</p>
  </div>
<% end %>
ERB

# ---- ApplicationHelper additions (if not already present) ----
cat > app/helpers/application_helper.rb << 'RUBY'
module ApplicationHelper
  def status_badge(status)
    colors = {
      "draft" => "badge-ghost",
      "review" => "badge-warning",
      "approved" => "badge-success",
      "published" => "badge-info",
      "archived" => "badge-neutral"
    }
    content_tag :span, status.to_s.titleize, class: "badge #{colors[status.to_s] || 'badge-ghost'} badge-sm"
  end

  def approval_badge(decision)
    colors = {
      "pending" => "badge-ghost",
      "approved" => "badge-success",
      "rejected" => "badge-error",
      "changes_requested" => "badge-warning"
    }
    content_tag :span, decision.to_s.titleize, class: "badge #{colors[decision.to_s] || 'badge-ghost'} badge-sm"
  end
end
RUBY

echo "=== Document Management bootstrap complete ==="
