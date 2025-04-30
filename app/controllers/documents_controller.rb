class DocumentsController < ApplicationController
  before_action :set_documentable

  def index
    @documents = @documentable.documents
    @document = Document.new
  end

  def new
    @document = @documentable.documents.new
  end

  def create
    @document = @documentable.documents.new(document_params)
    if @document.save
      redirect_to polymorphic_path([ @documentable, :documents ]), notice: "Document uploaded successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @document = @documentable.documents.find(params[:id])
  end

  private

  def set_documentable
    klass = [ Vehicle, Driver ].detect { |c| params["#{c.name.underscore}_id"] }
    @documentable = klass.find(params["#{klass.name.underscore}_id"])
  end

  def document_params
    params.require(:document).permit(:title, :document_type, :issue_date, :expiry_date, :file)
  end
end
