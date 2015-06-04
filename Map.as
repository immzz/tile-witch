package {
	import flash.events.Event;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.net.FileFilter;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import fl.data.DataProvider;
	import flash.utils.Dictionary;
	import flash.display.Stage;
	import flash.display.MovieClip;

	public class Map {
		public static var BLOCK_SIZE: Number = 32;
		public var n_block_x: Number;
		public var n_block_y: Number;
		public var layers: Array;
		private var next_layer_index = 0;
		public var tilesets: Array;
		private var m:Map;


		public function Map(nBlocksX: Number, nBlocksY: Number) {
			m = this;
			n_block_x = nBlocksX;
			n_block_y = nBlocksY;
			var collision_layer: Layer = new Layer(m,next_layer_index, n_block_x, n_block_y, true);
			next_layer_index++;
			tilesets = new Array();
			layers = new Array();
			layers.unshift(collision_layer);
		}

		public function createLayer(): Layer {
			return createLayerAt(0, false);
		}

		public function createLayerAt(index: Number, collision: Boolean): Layer {
			trace("CREATE LAYER AT " + index);
			var layer: Layer = new Layer(m,next_layer_index, n_block_x, n_block_y, collision);
			next_layer_index++;
			for (var i: Number = layers.length - 1; i >= index; i--) {
				layers[i + 1] = layers[i];
			}
			layers[index] = layer;
			return layer;
		}

		public function removeLayerAt(index: Number): Layer {
			if (index == layers.length - 1) {
				return null;
			}
			var removed_layer: Layer = layers[index];
			layers.splice(index, 1);
			return removed_layer;
		}

		public function getNumLayers(): Number {
			return layers.length;
		}

		public function swapLayers(index1: Number, index2: Number): Boolean {
			if (index1 >= layers.length - 1 || index2 >= layers.length - 1 || index1 < 0 || index2 < 0) {
				return false;
			}
			var temp: Layer = layers[index1];
			layers[index1] = layers[index2];
			layers[index2] = temp;
			return true;
		}

		public function moveUpLayer(index: Number) {
			return swapLayers(index, index + 1);
		}

		public function moveDownLayer(index: Number) {
			return swapLayers(index, index - 1);
		}

		public function syncTilesetsWithDataprovider(dp: DataProvider): void {
			for (var i: Number = 0; i < dp.length; i++) {
				tilesets.push(dp.getItemAt(i).label);
			}
		}

		/*
		Collision layer lies on top of all layers
		*/
		public function getCollisionLayer(): Layer {
			return layers[layers.length - 1];
		}

		public function getLayerAt(index: Number): Layer {
			return layers[index];
		}

		public function addTile(tile: Tile, layer: Layer, block_x: Number, block_y: Number): Boolean {
			return layer.addTile(tile, block_x, block_y);
		}
		
		public function isEmpty():Boolean{
			for (var i: Number = 0; i < layers.length; i++) {
				if(!layers[i].isEmpty()){
					return false;
				}
			}
			return true;
		}

		public function getBoundary(): Object {
			var lx: Number = 9999999;
			var rx: Number = -9999999;
			var ty: Number = 9999999;
			var by: Number = -9999999;
			for (var i: Number = 0; i < layers.length; i++) {
				if(layers[i].isEmpty()){
					continue;
				}
				if (layers[i].lx < lx) {
					lx = layers[i].lx;
				}
				if (layers[i].rx > rx) {
					rx = layers[i].rx;
				}
				if (layers[i].ty < ty) {
					ty = layers[i].ty;
				}
				if (layers[i].by > by) {
					by = layers[i].by;
				}
			}
			return {
				"lx": lx,
				"rx": rx,
				"ty": ty,
				"by": by
			}
		}

		public function reset(): void {
			tilesets = new Array();
			layers = new Array();
			next_layer_index = 0;
			next_layer_index++;
		}

		public function getCanvasWidth(): Number {
			if(isEmpty()){
				return 0;
			}
			var boundary: Object = getBoundary();
			return boundary.rx - boundary.lx + 1;
		}

		public function getCanvasHeight(): Number {
			if(isEmpty()){
				return 0;
			}
			var boundary: Object = getBoundary();
			return boundary.by - boundary.ty + 1;
		}

		public function save(tileset_list_dp: DataProvider): void {
			var typeFilter: FileFilter = new FileFilter("Data", "*.map");
			var fileToSave: File = File.documentsDirectory.resolvePath('my.map');
			fileToSave.addEventListener(Event.SELECT, saveFileSelected);
			fileToSave.browseForSave("Save");
			function saveFileSelected(event: Event): void {
				var fs: FileStream = new FileStream();
				fs.open(fileToSave, FileMode.WRITE);
				//Map info
				fs.writeUTFBytes("----BEGIN MAP INFO----\n");
				var boundary:Object = getBoundary();
				fs.writeUTFBytes(JSON.stringify({
					"lx":boundary.lx,
					"ty":boundary.ty,
					"width": getCanvasWidth(),
					"height": getCanvasHeight(),
					"num_layers": layers.length
				}) + '\n');
				//Tilesets
				for (i = 0; i < tileset_list_dp.length; i++) {
					fs.writeUTFBytes("----BEGIN TILESET " + i + "----\n");
					fs.writeUTFBytes(tileset_list_dp.getItemAt(i).label + "\n");
					var tile_dp: DataProvider = tileset_list_dp.getItemAt(i).dp;
					for (j = 0; j < tile_dp.length; j++) {
						var t: Tile = tile_dp.getItemAt(j).tile;
						fs.writeUTFBytes(JSON.stringify(t) + "\n");
					}
				}
				//Layers
				for (var i: Number = 0; i < layers.length; i++) {
					trace("LAYER BOUNDARY",layers[i].lx,layers[i].rx);
					if(!layers[i].is_collision_layer && layers[i].isEmpty()){
						continue;
					}
					fs.writeUTFBytes("----BEGIN LAYER " + i + "----\n");
					fs.writeUTFBytes(JSON.stringify({
						"id": layers[i].id,
						"collision": layers[i].is_collision_layer
					}) + "\n");
					fs.writeUTFBytes(JSON.stringify(layers[i].getOutputMatrix()) + '\n');
					var free_ovj_arr: Array = new Array();
					for (var j: Number = 0; j < layers[i].free_objects.length; j++) {
						free_ovj_arr.push({
							"md5": layers[i].free_objects[j].tile.md5,
							"x": layers[i].free_objects[j].x,
							"y": layers[i].free_objects[j].y
						});
					}
					fs.writeUTFBytes(JSON.stringify(free_ovj_arr) + '\n');
				}
				fs.close();
			}
		}

		public function load(tileset_list_dp: DataProvider,root:Object): void {
			var fileToOpen: File = File.documentsDirectory.resolvePath('my.map');
			fileToOpen.addEventListener(Event.SELECT, openFileSelected);

			function openFileSelected(event: Event): void {
				var fs: FileStream = new FileStream();
				fs.open(fileToOpen, FileMode.READ);
				var file_str: String = fs.readUTFBytes(fs.bytesAvailable);
				fs.close();
				// Reset Map
				reset();
				
				// Load Map
				var strs: Array = file_str.split("\n");
				// Load Map Info
				trace("LOAD MAP INFO");
				var map_info: Object = JSON.parse(strs[1]);
				var current_line_index = 2;
				// Load Tilesets
				trace("LOAD TILESETS");
				var tile_dict:Dictionary = new Dictionary();
				var current_tileset_dp:DataProvider = null;
				while(current_line_index < strs.length){
					if (strs[current_line_index].indexOf("----BEGIN LAYER") >= 0) {
						break;
					}
					if (strs[current_line_index].indexOf("----BEGIN TILESET") >= 0) {
						current_line_index++;
						var tileset_label:String = strs[current_line_index];
						current_tileset_dp = new DataProvider();
						tileset_list_dp.addItem({
							"label": tileset_label,
							"dp": current_tileset_dp
						});
						current_line_index++;
						continue;
					}
					var t = new Tile(strs[current_line_index]);
					tile_dict[t.md5] = t;
					var item: Object = Tile.generateTileItem(t);
					item.source.addChild(new Check());
					item.source.getChildAt(1).visible = false;
					current_tileset_dp.addItem(item);
					current_line_index++;
				}
				// Load Layers
				trace("LOAD LAYERS");
				while(current_line_index < strs.length){
					trace("LOOOOOP");
					if (strs[current_line_index].indexOf("----BEGIN LAYER") >= 0) {
						trace("NEW LAYER");
						current_line_index++;
						var layer_info = JSON.parse(strs[current_line_index]);
						current_line_index++;
						var new_layer:Layer = new Layer(m,next_layer_index, n_block_x, n_block_y, layer_info.collision);
						next_layer_index++;
						layers.push(new_layer);
						
						var output_matrix = JSON.parse(strs[current_line_index]);
						//Fill in tile matrix
						if(output_matrix.length > 0){
							var start_x:Number = map_info.lx;
							var start_y:Number = map_info.ty;
							trace("LOAD START",start_x,start_y,output_matrix.length,output_matrix[0].length);
							for(var i:Number=0;i<output_matrix.length;i++){
								for(var j:Number=0;j<output_matrix[0].length;j++){
									if(output_matrix[i][j] == Layer.EMPTY_ELEMENT_OUTPUT){
										continue;
									}
									new_layer.matrix[i+start_x][j+start_y] = tile_dict[output_matrix[i][j]];
								}
							}
						}
						//Fill in free objects
						current_line_index++;
						var free_obj_arr = JSON.parse(strs[current_line_index]);
						for(i=0;i<free_obj_arr.length;i++){
							new_layer.free_objects[i] = {"tile":tile_dict[free_obj_arr[i].md5],"x":free_obj_arr[i].x,"y":free_obj_arr[i].y};
						}
						
						new_layer.updateBoundry();
						current_line_index++;
						
					}else{
						trace("OOPS");
						break;
					}
				}
				root.syncLayersWithDataProvider();
				root.updateMap();
			}
			var typeFilter: FileFilter = new FileFilter("Data", "*.map");
			fileToOpen.browseForOpen("Open", [typeFilter]);
		}
	}

}