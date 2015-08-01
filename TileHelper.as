package {
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import com.adobe.crypto.MD5;
	import flash.display.MovieClip;
	import fl.data.DataProvider;
	import flash.events.Event;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.net.FileFilter;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	public class TileHelper {
		public static function loadTilesetIntoDataProvider(tileset_list_dp: DataProvider, tileset_dps: Array, show_check: Boolean): void {
			var fileToOpen: File = File.documentsDirectory.resolvePath('my.ts');
			fileToOpen.addEventListener(Event.SELECT, openFileSelected);
			var file_info: Object = new Object();
			function openFileSelected(event: Event): void {
				var opened_file_name:String = fileToOpen.name;
				var created_new_dp:Boolean = true;
				var tileset_dp:DataProvider = null;
				for(var i:Number = 0;i<tileset_list_dp.length;i++){
					if(tileset_list_dp.getItemAt(i).label == opened_file_name){
						tileset_dp = tileset_list_dp.getItemAt(i).dp;
						created_new_dp = false;
						break;
					}
				}
				if(!tileset_dp){
					tileset_dp = new DataProvider();
				}
				var fs: FileStream = new FileStream();
				fs.open(fileToOpen, FileMode.READ);
				var file_str: String = fs.readUTFBytes(fs.bytesAvailable);
				fs.close();
				var strs: Array = file_str.split("\n");
				for each(var str: String in strs) {
					if (str.length == 0) {
						continue;
					}
					var imported_tile: Tile = new Tile(str);
					var item: Object = Tile.generateTileItem(imported_tile);

					item.source.addChild(new Check());
					if (!show_check) {
						item.source.getChildAt(1).visible = false;
					}

					var hasTile: Boolean = false;
					for (var l: Number = 0; l < tileset_dp.length; l++) {
						if (tileset_dp.getItemAt(l).tile.md5 == imported_tile.md5) {
							tileset_dp.replaceItemAt(item, l);
							hasTile = true;
							break;
						}
					}
					if (!hasTile) {
						tileset_dp.addItem(item);
					}
				}
				if(created_new_dp){
					tileset_list_dp.addItem({
						"label": fileToOpen.name,
						"dp": tileset_dp
					});
					tileset_dps.unshift(tileset_dp);
				}
			}
			var typeFilter: FileFilter = new FileFilter("Data", "*.ts");
			fileToOpen.browseForOpen("Open", [typeFilter]);
		}
	}

}