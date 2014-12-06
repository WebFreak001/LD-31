module GameScene;

import EncoShared;
import EncoDesktop;
import EncoGL3;

import std.file;

enum MAT_HOUSEL1 = 0;
enum MAT_TRAILER1 = 1;
enum MAT_STONE = 2;
enum MAT_STREET = 3;
enum MAT_ERROR = 4;

class Game3DLayer : RenderLayer
{
	Mesh[] floor;
	Mesh[] error;
	Mesh[] stone;
	Mesh[] street;
	Mesh[] houses_low;

	override void init(Scene scene)
	{
		floor = Mesh.loadFromObj("meshes/floor.obj", 0);
		error = Mesh.loadFromObj("meshes/error.obj", 0);
		stone = Mesh.loadFromObj("meshes/stone.obj", 0);
		street = Mesh.loadFromObj("meshes/street.obj", 0);
		houses_low = Mesh.loadFromObj("meshes/houses_low.obj", 0);

		materials = [
					GLMaterial.load(scene.renderer, "materials/houseL1.json"),
					GLMaterial.load(scene.renderer, "materials/trailer1.json"),
					GLMaterial.load(scene.renderer, "materials/stone.json"),
					GLMaterial.load(scene.renderer, "materials/street.json"),
					GLMaterial.load(scene.renderer, "materials/error.json"),
					];

		random = new Random();
		
		addMesh(floor[0], GLMaterial.load(scene.renderer, "materials/grass.json"), vec3(-5, 0, -5));
		addStone(stone[1], materials[MAT_STONE], vec3(-110, 0, -20));
		addStone(stone[1], materials[MAT_STONE], vec3(-120, 0, -30));
		addStone(stone[0], materials[MAT_STONE], vec3(-130, 0, -10));
		addStone(stone[1], materials[MAT_STONE], vec3(-150, 0, -50));
		addStone(stone[1], materials[MAT_STONE], vec3(-200, 0, 10));
		addStone(stone[1], materials[MAT_STONE], vec3(-130, 0, 20));
		addStone(stone[1], materials[MAT_STONE], vec3(-140, 0, -30));
		
		for(int x = -40; x < -10; x++)
			addMesh(street[0], materials[MAT_STREET], vec3(x * 10, 0, 0));

		save();
		load("save0");
	}

	private Mesh getMesh(ubyte i)
	{
		if(i < 16) // 0 - 15
		{
			return houses_low[i];
		}
		// TODO: Add Mid, High houses
		if(i < 64) // 48 - 63
		{
			if(i == 51) return street[0];
			if(i == 52) return street[3];
			if(i == 53) return street[3];
			if(i == 54) return street[3];
			if(i == 55) return street[3];
			if(i == 56) return street[2];
			if(i == 57) return street[2];
			if(i == 58) return street[2];
			return street[i - 48];
		}
		if(i < 80) // 64 - 79
		{
			return stone[i - 64];
		}
		return error[0];
	}

	private vec3 getRotation(ubyte i)
	{
		switch(i)
		{
		case 51:
		case 54:
		case 57:
			return vec3(0, 1.57079633, 0);
		case 53:
		case 58:
			return vec3(0, -1.57079633, 0);
		case 55:
		case 56:
			return vec3(0, 1.57079633 * 2, 0);
		default:
			return vec3(0);
		}
	}

	private Material getMaterial(ubyte i)
	{
		switch(i)
		{
		case 0:
			return materials[MAT_HOUSEL1];
		case 1:
			return materials[MAT_TRAILER1];
		case 48: // Street Straight
		case 49: // Street Cross
		case 50: // Street T - Up
		case 51: // Street Straight Up
		case 52: // Street Corner Up Right
		case 53: // Street Corner Up Left
		case 54: // Street Corner Down Right
		case 55: // Street Corner Down Left
		case 56: // Street T - Down
		case 57: // Street T | Right
		case 58: // Street T | Left
			return materials[MAT_STREET];
		default:
			return materials[MAT_ERROR];
		}
	}

	private void load(string save)
	{
		ubyte[] data = cast(ubyte[])read("saves/" ~ save ~ ".bld31");
		ubyte width = data[0];
		ubyte height = data[1];

		ubyte[] level = data[2 .. width * height];

		for(int i = 0; i < level.length; i++)
			if(level[i] != 255)
				addMesh(getMesh(level[i]), getMaterial(level[i]), vec3(i % width * 10 - 100, 0, i / width * 10 - 100), getRotation(level[i]));
	}

	private void save()
	{
		ubyte[] data;
		ubyte width = 20;
		ubyte height = 20;
		ubyte[] level = new ubyte[width * height];

		level[] = 255;
		level[0 + 10 * width] = 49;
		level[1 + 10 * width] = 48;
		level[2 + 10 * width] = 48;
		level[3 + 10 * width] = 48;
		level[4 + 10 * width] = 58;
		

		level[0 + 6 * width] = 54;
		level[0 + 7 * width] = 51;
		level[0 + 8 * width] = 51;
		level[0 + 9 * width] = 51;

		level[4 + 6 * width] = 55;
		level[4 + 7 * width] = 51;
		level[4 + 8 * width] = 51;
		level[4 + 9 * width] = 51;

		level[1 + 6 * width] = 48;
		level[2 + 6 * width] = 48;
		level[3 + 6 * width] = 48;

		
		level[0 + 11 * width] = 51;
		level[0 + 12 * width] = 51;
		level[0 + 13 * width] = 51;
		level[0 + 14 * width] = 52;

		level[4 + 11 * width] = 51;
		level[4 + 12 * width] = 51;
		level[4 + 13 * width] = 51;
		level[4 + 14 * width] = 53;

		level[1 + 14 * width] = 48;
		level[2 + 14 * width] = 48;
		level[3 + 14 * width] = 48;

		// HOUSES
		level[1 + 9 * width] = 1;
		level[2 + 9 * width] = 0;
		level[3 + 9 * width] = 0;
		
		level[1 + 8 * width] = 0;
		level[3 + 8 * width] = 0;

		level[1 + 7 * width] = 0;
		level[2 + 7 * width] = 0;
		level[3 + 7 * width] = 0;


		level[1 + 11 * width] = 0;
		level[2 + 11 * width] = 0;
		level[3 + 11 * width] = 0;

		level[1 + 12 * width] = 0;
		level[3 + 12 * width] = 0;

		level[1 + 13 * width] = 0;
		level[2 + 13 * width] = 0;
		level[3 + 13 * width] = 0;

		data ~= [width, height];
		data ~= level;
		write("saves/save0.bld31", data);
	}

	private void addMesh(Mesh mesh, Material material, vec3 position, vec3 rotation = vec3(0))
	{
		auto obj = new MeshObject(mesh, material);
		obj.transform.position = position;
		obj.transform.rotation = rotation;
		addGameObject(obj);
	}

	private void addTrailer(Mesh mesh, Material material, vec3 position)
	{
		auto obj = new MeshObject(mesh, material);
		obj.transform.position = position;
		obj.transform.rotation.y = (random.nextFloat() - 0.5f) * 0.2f;
		addGameObject(obj);
	}

	private void addStone(Mesh mesh, Material material, vec3 position)
	{
		auto obj = new MeshObject(mesh, material);
		obj.transform.position = position;
		obj.transform.rotation.y = (random.nextFloat() - 0.5f) * 3.1415926f;
		addGameObject(obj);
	}

	
	Material[] materials;
	Random random;
}

class GameScene : Scene
{
	override void init()
	{
		addLayer(new Game3DLayer());
	}
}