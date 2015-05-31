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
		public static function loadTilesetIntoDataProvider(dp: DataProvider,show_check:Boolean): String {
			var fileToOpen: File = File.documentsDirectory.resolvePath('my.ts');
			fileToOpen.addEventListener(Event.SELECT, openFileSelected);

			function openFileSelected(event: Event): void {
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
					if(!show_check){
						item.source.getChildAt(1).visible = false;
					}
					trace(fileToOpen.name);
					var hasTile: Boolean = false;
					for (var l: Number = 0; l < dp.length; l++) {
						if (dp.getItemAt(l).tile.md5 == imported_tile.md5) {
							dp.replaceItemAt(item, l);
							hasTile = true;
							break;
						}
					}
					if (!hasTile) {
						dp.addItem(item);
					}
				}

			}
			var typeFilter: FileFilter = new FileFilter("Data", "*.ts");
			fileToOpen.browseForOpen("Open", [typeFilter]);
			return fileToOpen.name;
		}
	}

}