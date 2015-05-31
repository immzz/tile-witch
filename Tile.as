package {
	import flash.display.Shape;
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

	public class Tile {
		public var width: Number;
		public var height: Number;
		public var file_name: String;
		public var bl_x_offset: Number;
		public var bl_y_offset: Number;
		public var collision_matrix: Array;
		public var bitmapdata: BitmapData;
		public var md5: String;

		public function Tile(str: String, bitmap: Bitmap = null): void {
			if (bitmap) {
				//build from Bitmap
				buildFromBitmap(str, bitmap);
			} else {
				//build from JSON
				buildFromJSON(str);
			}
		}



		public static function generateTileItem(tile: Tile): Object {
			var old_bitmap: Bitmap = new Bitmap(tile.bitmapdata);
			var new_bitmap = new Bitmap(tile.bitmapdata);
			var new_sp: Sprite = new Sprite();
			new_sp.addChild(new_bitmap);
			return {
				label: tile.file_name,
				source: new_sp,
				scaleContent: true,
				width: new_bitmap.width,
				height: new_bitmap.height,
				bitmap: old_bitmap,
				tile: tile
			};
		}

		public function generatePlacementItem(): Sprite {
			var sp:Sprite = new Sprite();
			sp.addChild(new Bitmap(bitmapdata));
			sp.getChildAt(0).x = bl_x_offset;
			sp.getChildAt(0).y = -height-bl_y_offset;
			var line_color = 0xFFFFFF;
			var lines: Shape = new Shape();
			lines.graphics.beginFill(0xFF0000, 0.6);
			lines.graphics.drawRect(0, 0, getCollisionWidth()*Map.BLOCK_SIZE, -getCollisionHeight()*Map.BLOCK_SIZE);
			lines.graphics.endFill();
			sp.addChild(lines);
			return sp;
		}


		public function isProcessed(): Boolean {
			return collision_matrix.length > 0;
		}

		/**
		 * In number of blocks
		 */
		public function getCollisionWidth(): Number {
			return collision_matrix.length;
		}

		/**
		 * In number of blocks
		 */
		public function getCollisionHeight(): Number {
			if (collision_matrix.length > 0) {
				return collision_matrix[0].length;
			}
			return 0;
		}

		public function createMC(): MovieClip {
			var mc: MovieClip = new MovieClip();
			var bmp: Bitmap = new Bitmap(bitmapdata);
			mc.addChild(bmp);
			return mc;
		}

		public function hasCollisionPointAt(blockX: Number, blockY: Number): Boolean {
			return collision_matrix[blockX][blockY] == 1;
		}

		public function toJSON(s: String): * {
			return {
				"width": width,
				"height": height,
				"file_name": file_name,
				"bl_x_offset": bl_x_offset,
				"bl_y_offset": bl_y_offset,
				"collision_matrix": collision_matrix,
				"md5": md5,
				"bitmapdata": BitmapEncoder.encodeBase64(bitmapdata)
			};
		}

		public function buildFromBitmap(filename: String, bitmap: Bitmap): void {
			file_name = filename;
			width = bitmap.width;
			height = bitmap.height;
			bitmapdata = bitmap.bitmapData;
			md5 = MD5.hash(BitmapEncoder.encodeBase64(bitmapdata));
			collision_matrix = new Array();
		}

		public function buildFromJSON(str: String): void {
			var tile_info: Object = JSON.parse(str);
			bl_x_offset = tile_info.bl_x_offset;
			bl_y_offset = tile_info.bl_y_offset;
			file_name = tile_info.file_name;
			collision_matrix = tile_info.collision_matrix;
			width = tile_info.width;
			height = tile_info.height;
			md5 = tile_info.md5;
			bitmapdata = BitmapEncoder.decodeBase64(tile_info.bitmapdata);
		}
	}

}