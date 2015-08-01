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
	import com.adobe.images.PNGEncoder;
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	import com.adobe.crypto.MD5;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	public class Map {
		public static var BLOCK_SIZE: Number = 32;
		public var n_block_x: Number;
		public var n_block_y: Number;
		public var layers: Array;
		private var next_layer_index = 0;
		public var tilesets: Array;
		private var m:Map;
		public var collision_layer:Layer;
		public var trigger_layer:Layer;


		public function Map(nBlocksX: Number, nBlocksY: Number) {
			m = this;
			n_block_x = nBlocksX;
			n_block_y = nBlocksY;
			reset();
		}

		public function createLayerAt(index: Number, l_type: Number): Layer {
			trace("CREATE LAYER AT " + index);
			var layer: Layer = new Layer(m,next_layer_index, n_block_x, n_block_y, l_type);
			next_layer_index++;
			for (var i: Number = layers.length - 1; i >= index; i--) {
				layers[i + 1] = layers[i];
			}
			layers[index] = layer;
			return layer;
		}

		public function removeLayerAt(index: Number): Layer {
			if(layers[index].layer_type != Layer.LAYER_TYPE_GROUND
				&& layers[index].layer_type != Layer.LAYER_TYPE_OBJECT
				&& layers[index].layer_type != Layer.LAYER_TYPE_SKY
			){
				return null;
			}
			var removed_layer: Layer = layers[index];
			layers.splice(index, 1);
			return removed_layer;
		}

		public function getNumLayers(): Number {
			return layers.length;
		}

		/*
		  Only switching sky layers with other kind of layers is not permitted
		*/
		public function swapLayers(index1: Number, index2: Number): Boolean {
			if (index1 >= layers.length || index2 >= layers.length || index1 < 0 || index2 < 0) {
				return false;
			}
			if((
				   layers[index1].layer_type == Layer.LAYER_TYPE_SKY 
				|| layers[index2].layer_type == Layer.LAYER_TYPE_SKY
				|| layers[index1].layer_type == Layer.LAYER_TYPE_COLLISION
				|| layers[index2].layer_type == Layer.LAYER_TYPE_COLLISION
				|| layers[index1].layer_type == Layer.LAYER_TYPE_TRIGGER
				|| layers[index2].layer_type == Layer.LAYER_TYPE_TRIGGER
				)
				&&
				(layers[index1].layer_type != layers[index2].layer_type)
			){
				return false;
			}
			var temp: Layer = layers[index1];
			layers[index1] = layers[index2];
			layers[index2] = temp;
			return true;
		}

		public function moveUpLayer(index: Number):Boolean {
			return swapLayers(index, index + 1);
		}

		public function moveDownLayer(index: Number):Boolean {
			return swapLayers(index, index - 1);
		}
		
		public function adjustLayer(id:Number):void{
			var layer_index:Number = 0;
			while(layer_index<layers.length){
				if(layers[layer_index].id == id){
					break;
				}
				layer_index++;
			}
			if(layer_index >= layers.length){
				return;
			}
			var layer_to_adjust:Layer = layers[layer_index];
			if(layer_to_adjust.layer_type == Layer.LAYER_TYPE_SKY){
				layer_index++;
				//trace(layer_to_adjust.layer_name+" ADJUST TO",layer_index);
				while(layer_index<layers.length){
					if(layers[layer_index].layer_type == Layer.LAYER_TYPE_GROUND
						|| layers[layer_index].layer_type == Layer.LAYER_TYPE_OBJECT
						){
						var temp:Layer = layers[layer_index];
						layers[layer_index] = layer_to_adjust;
						layers[layer_index-1] = temp;
					}else{
						break;
					}
					layer_index++;
				}
			}else if(layer_to_adjust.layer_type < Layer.LAYER_TYPE_SKY){
				layer_index--;
				trace(layer_to_adjust.layer_name+" "+layer_to_adjust.layer_type+" ADJUST TO",layer_index);
				while(layer_index>=0){
					if(layers[layer_index].layer_type != Layer.LAYER_TYPE_GROUND
						&& layers[layer_index].layer_type != Layer.LAYER_TYPE_OBJECT){
						temp = layers[layer_index];
						layers[layer_index] = layer_to_adjust;
						layers[layer_index+1] = temp;
					}else{
						break;
					}
					layer_index--;
				}
			}
		}

		public function syncTilesetsWithDataprovider(dp: DataProvider): void {
			for (var i: Number = 0; i < dp.length; i++) {
				tilesets.push(dp.getItemAt(i).label);
			}
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
			next_layer_index = 1;
			tilesets = new Array();
			layers = new Array();
			//Init functional layers
			collision_layer = createLayerAt(0, Layer.LAYER_TYPE_COLLISION);
			trigger_layer = createLayerAt(0, Layer.LAYER_TYPE_TRIGGER);
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
		
		public function getNumNonEmptyLayers():Number{
			var num_layers:Number = 0;
			for(var i:Number=0;i<layers.length;i++){
				if(!layers[i].isEmpty()){
					num_layers++;
				}
			}
			return num_layers;
		}

		public function save(tileset_list_dp: DataProvider, save_bitmapdata:Boolean, layer_mcs:Dictionary, map_mc:MovieClip): void {
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
				trace("MAP BOUNDARY",JSON.stringify(boundary));
				fs.writeUTFBytes(JSON.stringify({
					"lx":boundary.lx,
					"ty":boundary.ty,
					"width": getCanvasWidth(),
					"height": getCanvasHeight(),
					"num_layers": getNumNonEmptyLayers()
				}) + '\n');
				//Tilesets
				for (i = 0; i < tileset_list_dp.length; i++) {
					fs.writeUTFBytes("----BEGIN TILESET " + i + "----\n");
					fs.writeUTFBytes(tileset_list_dp.getItemAt(i).label + "\n");
					var tile_dp: DataProvider = tileset_list_dp.getItemAt(i).dp;
					for (j = 0; j < tile_dp.length; j++) {
						var t: Tile = tile_dp.getItemAt(j).tile;
						if(save_bitmapdata){
							fs.writeUTFBytes(JSON.stringify(t) + "\n");
						}else{
							fs.writeUTFBytes(JSON.stringify({
								"width": t.width,
								"height": t.height,
								"file_name": t.file_name,
								"bl_x_offset": t.bl_x_offset,
								"bl_y_offset": t.bl_y_offset,
								"collision_matrix": t.collision_matrix,
								"md5": t.md5
							}) + "\n");
						}
					}
				}
				//Layers
				for (var i: Number = 0; i < layers.length; i++) {
					trace("LAYER BOUNDARY",layers[i].id,layers[i].lx,layers[i].rx,layers[i].ty,layers[i].by);
					if(layers[i].isEmpty()){
						continue;
					}
					fs.writeUTFBytes("----BEGIN LAYER " + i + "----\n");
					fs.writeUTFBytes(JSON.stringify({
						"id": layers[i].id,
						"layer_type": layers[i].layer_type,
						"layer_name": layers[i].layer_name
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
					
					if((layers[i].layer_type == Layer.LAYER_TYPE_GROUND || layers[i].layer_type == Layer.LAYER_TYPE_SKY)
						&& (!save_bitmapdata)){
						//Save for Unity
						//For Background & Sky layers
						var layer_mc:MovieClip = layer_mcs[layers[i].id];
						var bounds:Rectangle = layer_mc.getBounds(map_mc);
						var layer_bitmapdata:BitmapData = new BitmapData(layer_mc.width,layer_mc.height,true,0x00FFFFFF);
						layer_bitmapdata.draw(layer_mc,new Matrix(1,0,0,1,-bounds.x,-bounds.y));
						var ba: ByteArray = PNGEncoder.encode(layer_bitmapdata);
						var layer_image_md5:String = MD5.hash(BitmapEncoder.encodeBase64(layer_bitmapdata));
						var layer_file: File = File.documentsDirectory.resolvePath(fileToSave.parent.nativePath + "/" + layer_image_md5 + ".png");
						var newfileStream: FileStream = new FileStream();
						newfileStream.open(layer_file, FileMode.WRITE);
						newfileStream.writeBytes(ba, 0, ba.length);
						newfileStream.close();
						//Write layer image info as a free tile
						var layer_image_info:Object = {
								"md5": layer_image_md5,
								"x": bounds.x,
								"y": bounds.y+bounds.height
							};
						fs.writeUTFBytes(JSON.stringify(layer_image_info) + '\n');
					}
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
				next_layer_index = 1;
				layers = new Array();
				collision_layer = null;
				trigger_layer = null;
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
					if (strs[current_line_index] == "" || strs[current_line_index].indexOf("----BEGIN LAYER") >= 0) {
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
						var new_layer:Layer = new Layer(m,next_layer_index, n_block_x, n_block_y, layer_info.layer_type);
						new_layer.layer_name = layer_info.layer_name;
						next_layer_index++;
						layers.push(new_layer);
						if(new_layer.layer_type == Layer.LAYER_TYPE_COLLISION){
							collision_layer = new_layer;
						}
						if(new_layer.layer_type == Layer.LAYER_TYPE_TRIGGER){
							trigger_layer = new_layer;
						}
						
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
				// If functional layers not included in map, create empty one
				if(!trigger_layer){
					trigger_layer = createLayerAt(layers.length,Layer.LAYER_TYPE_TRIGGER);
				}
				if(!collision_layer){
					collision_layer = createLayerAt(layers.length,Layer.LAYER_TYPE_COLLISION);
				}
				root.syncLayersWithDataProvider();
				root.updateMap();
			}
			var typeFilter: FileFilter = new FileFilter("Data", "*.map");
			fileToOpen.browseForOpen("Open", [typeFilter]);
		}
	}

}