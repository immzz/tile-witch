package {
	import flash.display.Sprite;
	public class Layer {
		public static var EMPTY_ELEMENT = null;
		private static var EMPTY_FILL = null;
		public var id: Number;
		public var matrix: Array;
		public var is_collision_layer: Boolean;
		public var fill_matrix: Array;
		public var lx: Number;
		public var rx: Number;
		public var ty: Number;
		public var by: Number;

		public function Layer(layer_id: Number, nBlocksX: Number, nBlocksY: Number, is_collision: Boolean) {
			
			id = layer_id;
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
			trace("NEW LAYER matrix",layer_id);
			trace("NEW LAYER matrix",nBlocksX);
			trace("NEW LAYER matrix",matrix.length);
			is_collision_layer = is_collision;
			lx = 0;
			rx = 0;
			ty = 0;
			by = 0;
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
			trace("TILE ADDED AT "+blockX+","+blockY);
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

		private function updateBoundry(): void {
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
			lx = min_x;
			rx = max_x;
			ty = min_y;
			by = max_y;
		}
	}
}