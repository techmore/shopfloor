# The Approval model belongs_to :document, but the table was generated without the
# foreign key column, so approvals could never be attached to a document.
class AddDocumentToApprovals < ActiveRecord::Migration[8.1]
  def change
    add_reference :approvals, :document, foreign_key: true
  end
end
