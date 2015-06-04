package {
	import flash.display.Sprite;
	public class Layer {
		public static var EMPTY_ELEMENT = null;
		public static var EMPTY_ELEMENT_OUTPUT = "";
		private static var EMPTY_FILL = null;
		public var id: Number;
		public var matrix: Array;
		public var is_collision_layer: Boolean;
		public var fill_matrix: Array;
		public var free_objects:Array;
		public var lx: Number;
		public var rx: Number;
		public var ty: Number;
		public var by: Number;
		public var map:Map;

		public function Layer(m:Map,layer_id: Number, nBlocksX: Number, nBlocksY: Number, is_collision: Boolean) {
			id = layer_id;
			free_objects = new Array();
			matrix = new Array();
			fill_matrix = new Array();
			for (var i: Number = 0; i < nBlocksX; i++) {
				matrix[i] = new Array();
				fill_matrix[i] = new Array();
				for (var j: Number = 0; j < nBlocksY; j++) {
					matrix[i][j] = EMPTY_ELEMENT;
					fill_matrix[i][j] = EMPTY_FILL;
				}
			}
			is_collision_layer = is_collision;
			map = m;
			lx = -1;
			rx = -1;
			ty = -1;
			by = -1;
		}

		public function initFill(): void {
			for (var xpos: Number = lx; xpos <= rx; xpos++) {
				for (var ypos: Number = ty; ypos <= by; ypos++) {
					fill_matrix[xpos][ypos] = EMPTY_FILL;
				}
			}
		}
		
		public function getTile(blockX: Number, blockY: Number): Tile{
			return matrix[blockX][blockY];
		}

		public function isOccupied(blockX: Number, blockY: Number): Boolean {
			return !(matrix[blockX][blockY] == EMPTY_ELEMENT);
		}

		public function testTile(tile: Tile, blockX: Number, blockY: Number): Boolean {
			if ((blockX + tile.getCollisionWidth() - 1 >= getLayerWidth()) || (blockY - tile.getCollisionHeight() + 1 < 0)) {
				return false;
			}
			for (var x: Number = blockX; x < blockX + tile.getCollisionWidth(); x+=tile.getCollisionWidth()) {
				for (var y: Number = blockY; y < blockY + tile.getCollisionHeight(); y+= tile.getCollisionHeight()) {
					if (tile.hasCollisionPointAt(x - blockX, y - blockY) && isOccupied(x, y)) {
						return false;
					}
				}
			}
			return true;
		}
		
		public function testTiles(tile: Tile, sblockX: Number, sblockY: Number, eblockX: Number, eblockY: Number): Boolean {
			for (var x: Number = Math.min(sblockX,eblockX); x <= Math.max(sblockX,eblockX); x++) {
				for (var y: Number = Math.min(sblockY,eblockY); y <= Math.max(sblockY,eblockY); y++) {
					if(!testTile(tile,x,y)){
						return false;
					}
				}
			}
			return true;
		}

		public function fillTile(blockX: Number, blockY: Number): Object {
			var tile: Tile = matrix[blockX][blockY];
			var placement_item:Sprite = tile.generateSpriteItem();
			for (var x: Number = blockX; x < blockX + tile.getCollisionWidth(); x++) {
				for (var y: Number = blockY; y > blockY - tile.getCollisionHeight(); y--) {
					if (tile.hasCollisionPointAt(x - blockX, -(y - blockY))) {
						//trace("COLLISION POINT ",x,y);
						fill_matrix[x][y] = placement_item;
					}
				}
			}
			trace("TILE ADDED AT "+blockX+","+blockY);
			return {
				"object": placement_item,
				"block_x":blockX,
				"block_y":blockY
			};
		}
		
		public function getFillItem(blockX: Number, blockY: Number):Sprite{
			return fill_matrix[blockX][blockY];
		}

		public function needFill(xpos: Number, ypos: Number): Boolean {
			return isOccupied(xpos, ypos) && fill_matrix[xpos][ypos] == EMPTY_FILL;
		}

		public function getLayerWidth(): Number {
			return matrix.length;
		}

		public function getLayerHeight(): Number {
			return matrix[0].length;
		}
		
		public function getOutputMatrix():Array{
			var res:Array = new Array();
			if(isEmpty() || map.isEmpty()){
				return res;
			}
			var map_boundary:Object = map.getBoundary();
			for(var i:Number=map_boundary.lx;i<=map_boundary.rx;i++){
				res[i-map_boundary.lx] = new Array();
				for(var j:Number=map_boundary.ty;j<=map_boundary.by;j++){
					trace("OUTPUT",i,j,map_boundary.lx,map_boundary.ty);
					if(matrix[i][j]){
						res[i-map_boundary.lx][j-map_boundary.ty] = matrix[i][j].md5;
					}else{
						res[i-map_boundary.lx][j-map_boundary.ty] = EMPTY_ELEMENT_OUTPUT;
					}
				}
			}
			return res;
		}

		public function addTile(tile: Tile, blockX: Number, blockY: Number): Boolean {
			if (is_collision_layer && !testTile(tile, blockX, blockY)) {
				return false;
			}
			for (var x: Number = blockX; x < blockX + tile.getCollisionWidth(); x++) {
				for (var y: Number = blockY; y > blockY - tile.getCollisionHeight(); y--) {
					if (tile.hasCollisionPointAt(x - blockX, -(y - blockY))) {
						matrix[x][y] = tile;
					}
				}
			}
			//trace("TILE ADDED AT "+blockX+","+blockY);
			updateBoundry();
			return true;
		}
		
		public function addTileFree(tile: Tile, x: Number, y: Number): Boolean {
			free_objects.unshift({"tile":tile,"x":x,"y":y});
			updateBoundry();
			return true;
		}
		
		public function addTiles(tile: Tile, sblockX: Number, sblockY: Number, eblockX: Number, eblockY: Number): Boolean {
			for (var x: Number = Math.min(sblockX,eblockX); x <= Math.max(sblockX,eblockX); x+=tile.getCollisionWidth()) {
				for (var y: Number = Math.min(sblockY,eblockY); y <= Math.max(sblockY,eblockY); y+= tile.getCollisionHeight()) {
					matrix[x][y] = tile;
				}
			}

			updateBoundry();
			return true;
		}
		
		public function isEmpty():Boolean{
			return lx==-1&&rx==-1&&ty==-1&&by==-1;
		}
		
		public function removeTile(blockX: Number, blockY: Number): Sprite {
			var place_item:Sprite = fill_matrix[blockX][blockY];
			var tile:Tile = matrix[blockX][blockY];
			for(var xpos = blockX-tile.getCollisionWidth()+1;xpos<blockX+tile.getCollisionWidth();xpos++){
				for(var ypos = blockY-tile.getCollisionHeight()+1;ypos<blockY+tile.getCollisionHeight();ypos++){
					if(xpos >= 0 && xpos < getLayerWidth() && ypos >= 0 && ypos < getLayerHeight()){
						if(fill_matrix[xpos][ypos] == place_item){
							fill_matrix[xpos][ypos] = EMPTY_FILL;
							matrix[xpos][ypos] = EMPTY_ELEMENT;
						}
					}
				}
			}
			updateBoundry();			
			return place_item;
		}

		public function updateBoundry(): void {
			var min_x:Number = 999999;
			var max_x:Number = -1;
			var min_y:Number = 999999;
			var max_y:Number = -1;
			for (var xpos: Number = 0; xpos < getLayerWidth(); xpos++) {
				for (var ypos: Number = 0; ypos < getLayerHeight(); ypos++) {
					if (isOccupied(xpos, ypos)) {
						if (xpos < min_x) {
							min_x = xpos;
						}
						if (xpos > max_x) {
							max_x = xpos;
						}
						if (ypos < min_y) {
							min_y = ypos;
						}
						if (ypos > max_y) {
							max_y = ypos;
						}
					}
				}
			}
			for(var i:Number=0;i<free_objects.length;i++){
				var obj_lx:Number = Math.floor(free_objects[i].x / Map.BLOCK_SIZE);
				var obj_rx:Number = Math.floor((free_objects[i].x + free_objects[i].tile.width) / Map.BLOCK_SIZE);
				var obj_ty:Number = Math.floor(free_objects[i].y / Map.BLOCK_SIZE);
				var obj_by:Number = Math.floor((free_objects[i].y + free_objects[i].tile.height) / Map.BLOCK_SIZE);
				if(obj_lx < min_x){
					min_x = obj_lx;
				}
				if(obj_rx > max_x){
					max_x = obj_rx;
				}
				if(obj_ty < min_y){
					min_y = obj_ty;
				}
				if(obj_by > max_y){
					max_y = obj_by;
				}
			}
			if(!(min_x == 999999 && max_x == -1 && min_y == 999999 && max_y == -1)){
				lx = min_x;
				rx = max_x;
				ty = min_y;
				by = max_y;
			}
			trace("UPDATED BOUNDARY",lx,rx,ty,by);
		}
	}
}