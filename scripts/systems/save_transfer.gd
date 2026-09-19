class_name SaveTransfer
extends Node
signal import_ready(data: Dictionary)
signal status(message: String)
var dialog: FileDialog
var exported: Dictionary = {}
var upload_callback: JavaScriptObject

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		upload_callback = JavaScriptBridge.create_callback(_uploaded)
		JavaScriptBridge.eval("""
		window.insanariumChooseBackup = function(callback) {
		 const input = document.createElement('input'); input.type='file'; input.accept='.json,application/json';
		 input.style.display='none'; document.body.appendChild(input);
		 input.oncancel = () => input.remove();
		 input.onchange = async () => { const f=input.files[0]; if(!f) {input.remove(); return;}
		   if(f.size>2000000) {callback(''); input.remove(); return;} try {callback(await f.text());} catch(e) {callback('');} finally {input.remove();} };
		 input.click();
		};
		""", true)
	else:
		dialog = FileDialog.new()
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.filters = PackedStringArray(["*.json ; Aquarium save"])
		dialog.size = Vector2i(700, 500)
		dialog.file_selected.connect(_file_selected)
		add_child(dialog)

func export_save(data: Dictionary) -> void:
	exported = data
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(JSON.stringify(data, "\t").to_utf8_buffer(), "insanarium-backup.json", "application/json")
		status.emit("Backup download requested")
	else:
		dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		dialog.current_file = "insanarium-backup.json"
		dialog.popup_centered()

func import_save() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.get_interface("window").insanariumChooseBackup(upload_callback)
	else:
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dialog.popup_centered()

func _file_selected(path: String) -> void:
	if dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		status.emit("Backup exported" if LocalSave.write(exported, path) else "Export failed")
	else:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null or file.get_length() > BackupValidation.MAX_BYTES:
			status.emit("Invalid or oversized backup")
			return
		accept_text(file.get_as_text())

func _uploaded(arguments: Array) -> void:
	accept_text(str(arguments[0]) if not arguments.is_empty() else "")

func accept_text(text: String) -> void:
	var data := BackupValidation.parse(text)
	if data.is_empty():
		status.emit("Invalid backup — tank unchanged")
	else:
		import_ready.emit(data)
