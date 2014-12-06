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
	float tier;
	float happyness;
	MeshObject* bound;
	BlockType type;

	int numPersons;
	int maxPersons;
}

struct Person
{
	float x, y;

	float tx, ty;

	this(float x, float y)
	{
		this.x = x;
		this.y = y;

		tx = ty = 0;
	}


}

struct Level
{
	float width, height;
	float blockX, blockY;
	float happyness;

	string name;

	Block[] blocks;

	private Random random;

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

	Block add(MeshObject* obj, int x, int y, string model, int modelID, float rota, string mat, float tier = 0, BlockType type = BlockType.Street)
	{
		blocks.length++;
		blocks[blocks.length - 1] = Block(model, modelID, vec3(0, rota, 0), vec3(x, 0, y), mat, tier, 0, obj, type);
		return blocks[blocks.length - 1];
	}

	void remove(int x, int y)
	{
		blocks = std.algorithm.remove!(b => cast(int)(b.position.x + 0.5f) == x && cast(int)(b.position.z + 0.5f) == y)(blocks);
	}

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

	this(string file)
	{
		JSONValue value = parseJSON!string(std.file.readText(file));
		random = new Random();
		
		name = value["Name"].str;
		
		width = getFloatInt(&value, "Width", 20);
		height = getFloatInt(&value, "Height", 20);
		blockX = getFloatInt(&value, "BlockX", 10);
		blockY = getFloatInt(&value, "BlockY", 10);
		happyness = getFloatInt(&value, "Happyness", 1);

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
			b.tier = getFloatInt(&block, "Tier", 0);
			b.happyness = getFloatInt(&block, "Happyness", 1);
			b.type = cast(BlockType)getFloatInt(&block, "Type", 0);

			this.blocks[i] = b;
		}

		regenStreets();
		updateHouses();
	}

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

			if(up.model !is null && up.type == BlockType.Street) { numSur++; isUp = true; }
			if(down.model !is null && down.type == BlockType.Street) { numSur++; isDown = true; }
			if(right.model !is null && right.type == BlockType.Street) { numSur++; isRight = true; }
			if(left.model !is null && left.type == BlockType.Street) { numSur++; isLeft = true; }

			if(numSur == 0) block.modelID = 4;
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
			}
			else if(numSur == 4)
			{
				block.modelID = 1;
			}
			else
			{
				writeln("IMPOSSIBLE!");
			}
		}
		return block;
	}

	void update()
	{
		foreach(int i, Block block; blocks)
		{
			float hapOff = random.nextFloat() * 0.5f + block.happyness;

			float old = block.tier;
			if(hapOff > 0)
			{
				block.tier += hapOff * happyness * 0.01f * random.nextFloat();
			}
			else
			{
				block.tier += hapOff * 0.001f;
			}

			if(old >= 1 && block.tier < 1) block.tier = 1;
			if(block.tier < 0) block.tier = 0;

			blocks[i] = block;
		}
	}

	void updateHouses()
	{
		foreach(int i, Block block; blocks)
		{
			if(block.type == BlockType.Residential)
			{
				int baseTier = cast(int)(block.tier);

				if(baseTier < 3)
				{
					if(block.tier < 1)
					{
						block.modelID = 4;
					}
					else if(block.tier >= 1)
					{
						block.modelID = 3;
					}
					else if(block.tier > 2)
					{
						block.modelID = 2;
					}
					block.maxPersons = 0;
				}
				else if(baseTier < 8) // 3 ^ x
				{
					block.modelID = 1;
					block.material = "trailer1";
					block.maxPersons = 2;
				}
				else if(baseTier < 27)
				{
					block.modelID = 0;
					block.material = "houseL1";
					block.maxPersons = 6;
				}
				else if(baseTier < 64)
				{
					block.modelID = 0;
					block.material = "houseL1";
					block.maxPersons = 24;
				}
				else if(baseTier < 125)
				{
					block.modelID = 0;
					block.material = "houseL1";
					block.maxPersons = 60;
				}
				else if(baseTier < 216)
				{
					block.modelID = 0;
					block.material = "houseL1";
					block.maxPersons = 180;
				}

				block.numPersons = min(block.numPersons, block.maxPersons);
				blocks[i] = block;
			}
		}
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
				"Tier": JSONValue(block.tier),
				"Happyness": JSONValue(block.happyness),
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