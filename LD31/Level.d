module Level;

import std.json;
import std.algorithm;
import std.stdio;

import EncoShared;

enum BlockType : int
{
	Street = 0, Residential, Commercial, Industrial, Park, None
}

struct Block
{
	string model;
	int modelID;
	vec3 rotation;
	vec3 position;
	string material;
	MeshObject* bound;
	BlockType type;
}

class Level
{
	float width, height;
	float blockX, blockY;

	string name;

	Block[] blocks;

	int[] astarStreet;

	private Random random;

	this(string file)
	{
		JSONValue value = parseJSON!string(std.file.readText(file));
		random = new Random();
		
		name = value["Name"].str;
		
		width = getFloatInt(&value, "Width", 20);
		height = getFloatInt(&value, "Height", 20);
		blockX = getFloatInt(&value, "BlockX", 10);
		blockY = getFloatInt(&value, "BlockY", 10);

		auto blocks = value["Blocks"].array;

		this.blocks.length = blocks.length;

		foreach(int i, JSONValue block; blocks)
		{
			Block b = Block();
			b.model = block["Model"].str;
			b.modelID = cast(int)block["ID"].integer;
			auto rot = block["Rotation"].array;
			b.rotation = vec3(getFloatIntArray(rot, 0, 0), getFloatIntArray(rot, 1, 0), getFloatIntArray(rot, 2, 0));
			auto pos = block["Position"].array;
			b.position = vec3(getFloatIntArray(pos, 0, 0), 0, getFloatIntArray(pos, 1, 0));
			b.material = block["Material"].str;
			b.type = cast(BlockType)getFloatInt(&block, "Type", 0);

			this.blocks[i] = b;
		}

		astarStreet = new int[cast(int)(width * height)];

		regenStreets();
	}

	private float getFloatInt(JSONValue* value, const string name, float def)
	{
		try
		{
			if(value.opIndex(name).type == JSON_TYPE.FLOAT)
				return value.opIndex(name).floating;
			if(value.opIndex(name).type == JSON_TYPE.INTEGER)
				return cast(float)value.opIndex(name).integer;
			return def;
		}
		catch
		{
			return def;
		}
	}

	private float getFloatIntArray(JSONValue[] value, const size_t key, float def)
	{
		try
		{
			if(value[key].type == JSON_TYPE.FLOAT)
				return value[key].floating;
			if(value[key].type == JSON_TYPE.INTEGER)
				return cast(float)value[key].integer;
			return def;
		}
		catch
		{
			return def;
		}
	}

	Block add(MeshObject* obj, int x, int y, string model, int modelID, float rota, string mat, BlockType type = BlockType.Street)
	{
		blocks.length++;
		blocks[blocks.length - 1] = Block(model, modelID, vec3(0, rota, 0), vec3(x, 0, y), mat, obj, type);
		return blocks[blocks.length - 1];
	}

	void remove(int x, int y)
	{
		blocks = std.algorithm.remove!(b => cast(int)(b.position.x + 0.5f) == x && cast(int)(b.position.z + 0.5f) == y)(blocks);
	}

	bool hasBlock(float x, float y) { return hasBlock(cast(int)x, cast(int)y); }

	bool hasBlock(int x, int y)
	{
		foreach(Block block; blocks)
		{
			int bx = cast(int)(block.position.x + 0.5f);
			int by = cast(int)(block.position.z + 0.5f);

			if(bx == x && by == y)
				return true;
		}
		return false;
	}
	
	Block getBlock(float x, float y) { return getBlock(cast(int)x, cast(int)y); }

	Block getBlock(int x, int y)
	{
		if(y == 10 && x < 0) { Block b = Block(); b.type = BlockType.Street; return b; }
		if(x < 0 || y < 0 || x >= width || y >= height)
		{
			Block b = Block();
			b.type = BlockType.None;
			return b;
		}
		foreach(Block block; blocks)
		{
			int bx = cast(int)(block.position.x + 0.5f);
			int by = cast(int)(block.position.z + 0.5f);

			if(bx == x && by == y)
				return block;
		}
		Block b = Block();
		b.type = BlockType.None;
		return b;
	}

	Block postProcessStreet(Block block)
	{
		if(block.type == BlockType.Street)
		{
			int numSur = 0;
			bool isUp = false, isDown = false, isRight = false, isLeft = false;
				
			int x = cast(int)(block.position.x + 0.5f);
			int y = cast(int)(block.position.z + 0.5f);
				
			auto up = getBlock(x, y - 1);
			auto down = getBlock(x, y + 1);
			auto right = getBlock(x + 1, y);
			auto left = getBlock(x - 1, y);

			if(up.type == BlockType.Street) { numSur++; isUp = true; }
			if(down.type == BlockType.Street) { numSur++; isDown = true; }
			if(right.type == BlockType.Street) { numSur++; isRight = true; }
			if(left.type == BlockType.Street) { numSur++; isLeft = true; }
			

			if(numSur == 0)
			{
				block.modelID = 4;
				astarStreet[x + y * cast(int)width] = 1;
			}
			else if(numSur == 1)
			{
				block.modelID = 5;
				if(isRight)
					block.rotation = vec3(0, 0, 0);
				if(isLeft)
					block.rotation = vec3(0, 180, 0);
				if(isUp)
					block.rotation = vec3(0, -90, 0);
				if(isDown)
					block.rotation = vec3(0, 90, 0);
				astarStreet[x + y * cast(int)width] = 1;
			}
			else if(numSur == 2)
			{
				block.modelID = 0;
				if(isLeft && isRight)
				{
					block.rotation = vec3(0, 0, 0);
				}
				if(isUp && isDown)
				{
					block.rotation = vec3(0, 90, 0);
				}
				if(isRight && isUp)
				{
					block.modelID = 3;
					block.rotation = vec3(0, 0, 0);
				}
				if(isLeft && isUp)
				{
					block.modelID = 3;
					block.rotation = vec3(0, -90, 0);
				}
				if(isRight && isDown)
				{
					block.modelID = 3;
					block.rotation = vec3(0, 90, 0);
				}
				if(isLeft && isDown)
				{
					block.modelID = 3;
					block.rotation = vec3(0, 180, 0);
				}
				astarStreet[x + y * cast(int)width] = 1;
			}
			else if(numSur == 3)
			{
				block.modelID = 2;
				if(!isLeft)
				{
					block.rotation = vec3(0, 90, 0);
				}
				if(!isUp)
				{
					block.rotation = vec3(0, 180, 0);
				}
				if(!isRight)
				{
					block.rotation = vec3(0, -90, 0);
				}
				if(!isDown)
				{
					block.rotation = vec3(0, 0, 0);
				}
				astarStreet[x + y * cast(int)width] = 2;
			}
			else if(numSur == 4)
			{
				block.modelID = 1;
				astarStreet[x + y * cast(int)width] = 3;
			}
			else
			{
				writeln("IMPOSSIBLE!");
			}
		}
		return block;
	}

	void updateStreets(int x, int y)
	{
		foreach(int i, Block block; blocks)
		{
			if(x == cast(int)(block.position.x + 0.5f) && y == cast(int)(block.position.z + 0.5f))
			{
				blocks[i] = postProcessStreet(block);
			}
		}
	}

	void regenStreets()
	{
		foreach(int i, Block block; blocks)
		{
			blocks[i] = postProcessStreet(block);
		}
	}

	void save(string file)
	{
		JSONValue root = ["Name": JSONValue(name), "Width": JSONValue(cast(float)width), "Height": JSONValue(cast(float)height), "BlockX": JSONValue(cast(float)blockX), "BlockY": JSONValue(cast(float)blockY), "Blocks": JSONValue(0)];

		JSONValue[] blocks;

		foreach(Block block; this.blocks)
		{
			JSONValue b = [
				"Model": JSONValue(block.model),
				"ID": JSONValue(block.modelID),
				"Type": JSONValue(cast(int)block.type),
				"Material": JSONValue(block.material),
				"Rotation": JSONValue([cast(float)block.rotation.x, cast(float)block.rotation.y, cast(float)block.rotation.z]),
				"Position": JSONValue([cast(float)block.position.x, cast(float)block.position.z])];

			blocks.length++;
			blocks[blocks.length - 1] = b;
		}

		root["Blocks"].array = blocks;

		std.file.write(file, toJSON(&root, false));
	}
}