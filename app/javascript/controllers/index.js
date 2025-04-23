import { Application } from "@hotwired/stimulus"
import ManifestItemsController from "./manifest_items_controller"

const application = Application.start()
application.register("manifest-items", ManifestItemsController)

export default application