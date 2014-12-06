module Level;

import std.json;
import std.algorithm;
import std.stdio;
import EncoShared;

struct Block
{
	string model;
	int modelID;
	vec3 rotation;
	vec3 position;
	string material;
	float tier;
}

struct Level
{
	float width, height;
	float blockX, blockY;

	string name;

	Block[] blocks;

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

	Block add(int x, int y, string model, int modelID, float rota, string mat, float tier = 0)
	{
		blocks.length++;
		blocks[blocks.length - 1] = Block(model, modelID, vec3(0, rota, 0), vec3(x, 0, y), mat, tier);
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
		
		name = value["Name"].str;
		
		width = getFloatInt(&value, "Width", 20);
		height = getFloatInt(&value, "Height", 20);
		blockX = getFloatInt(&value, "BlockX", 10);
		blockY = getFloatInt(&value, "BlockY", 10);

		auto blocks = value["Blocks"].array;

		foreach(JSONValue block; blocks)
		{
			Block b = Block();
			b.model = block["Model"].str;
			b.modelID = cast(int)block["ID"].integer;
			auto rot = block["Rotation"].array;
			b.rotation = vec3(getFloatIntArray(rot, 0, 0), getFloatIntArray(rot, 1, 0), getFloatIntArray(rot, 2, 0));
			auto pos = block["Position"].array;
			b.position = vec3(getFloatIntArray(pos, 0, 0), 0, getFloatIntArray(pos, 1, 0));
			b.material = block["Material"].str;
			b.tier = getFloatInt(&value, "Tier", 0);

			this.blocks.length++;
			this.blocks[this.blocks.length - 1] = b;
		}

		regenStreets();
		updateHouses();
	}

	Block getBlock(int x, int y)
	{
		if(y == 10 && x < 0) return Block("street");
		foreach(Block block; blocks)
		{
			int bx = cast(int)(block.position.x + 0.5f);
			int by = cast(int)(block.position.z + 0.5f);

			if(bx == x && by == y)
				return block;
		}
		return Block();
	}

	Block postProcessStreet(Block block)
	{
		if(block.model == "street")
		{
			int numSur = 0;
			bool isUp = false, isDown = false, isRight = false, isLeft = false;
				
			int x = cast(int)(block.position.x + 0.5f);
			int y = cast(int)(block.position.z + 0.5f);
				
			auto up = getBlock(x, y - 1);
			auto down = getBlock(x, y + 1);
			auto right = getBlock(x + 1, y);
			auto left = getBlock(x - 1, y);

			if(up.model !is null && up.model == "street") { numSur++; isUp = true; }
			if(down.model !is null && down.model == "street") { numSur++; isDown = true; }
			if(right.model !is null && right.model == "street") { numSur++; isRight = true; }
			if(left.model !is null && left.model == "street") { numSur++; isLeft = true; }

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

	void updateHouses()
	{
		foreach(int i, Block block; blocks)
		{
			if(block.model == "house_low")
			{
				int baseTier = cast(int)(block.tier + 0.5f);

				if(baseTier == 0)
				{
					if(block.tier > 0.6f)
					{
						block.modelID = 3;
					}
					else if(block.tier > 0.3f)
					{
						block.modelID = 2;
					}
					else
					{
						block.modelID = 4;
					}
				}
				else if(baseTier == 1)
				{
					block.modelID = 1;
				}
				else if(baseTier == 2)
				{
					block.modelID = 0;
				}
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
				"Tier": JSONValue(block.tier),
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