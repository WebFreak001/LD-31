module Level;

import std.json;
import std.stdio;
import EncoShared;

struct Block
{
	string model;
	int modelID;
	vec3 rotation;
	vec3 position;
	string material;
}

struct Level
{
	float width, height;
	float blockX, blockY;

	string name;

	Block[] blocks;

	private float getFloatInt(JSONValue* value, const string name)
	{
		if(value.opIndex(name).type == JSON_TYPE.FLOAT)
			return value.opIndex(name).floating;
		if(value.opIndex(name).type == JSON_TYPE.INTEGER)
			return cast(float)value.opIndex(name).integer;
		assert(0);
	}

	private float getFloatIntArray(JSONValue[] value, const size_t key)
	{
		if(value[key].type == JSON_TYPE.FLOAT)
			return value[key].floating;
		if(value[key].type == JSON_TYPE.INTEGER)
			return cast(float)value[key].integer;
		assert(0);
	}

	this(string file)
	{
		JSONValue value = parseJSON!string(std.file.readText(file));
		
		name = value["Name"].str;
		
		width = getFloatInt(&value, "Width");
		height = getFloatInt(&value, "Height");
		blockX = getFloatInt(&value, "BlockX");
		blockY = getFloatInt(&value, "BlockY");

		auto blocks = value["Blocks"].array;

		foreach(JSONValue block; blocks)
		{
			Block b = Block();
			b.model = block["Model"].str;
			b.modelID = cast(int)block["ID"].integer;
			auto rot = block["Rotation"].array;
			b.rotation = vec3(getFloatIntArray(rot, 0), getFloatIntArray(rot, 1), getFloatIntArray(rot, 2));
			auto pos = block["Position"].array;
			b.position = vec3(getFloatIntArray(pos, 0), 0, getFloatIntArray(pos, 1));
			b.material = block["Material"].str;

			this.blocks.length++;
			this.blocks[this.blocks.length - 1] = b;
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