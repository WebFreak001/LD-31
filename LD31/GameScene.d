module GameScene;

import EncoShared;
import EncoDesktop;
import EncoGL3;

import std.file;
import Level;

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

	Mesh[][string] meshes;
	Material[string] materials;

	Random random;

	override void init(Scene scene)
	{
		floor = Mesh.loadFromObj("meshes/floor.obj", 0);
		error = Mesh.loadFromObj("meshes/error.obj", 0);
		stone = Mesh.loadFromObj("meshes/stone.obj", 0);
		street = Mesh.loadFromObj("meshes/street.obj", 0);
		houses_low = Mesh.loadFromObj("meshes/houses_low.obj", 0);
		
		meshes["floor"] = floor;
		meshes["stone"] = stone;
		meshes["street"] = street;
		meshes["houses_low"] = houses_low;

		materials = [
					"houseL1": GLMaterial.load(scene.renderer, "materials/houseL1.json"),
					"trailer1": GLMaterial.load(scene.renderer, "materials/trailer1.json"),
					"stone": GLMaterial.load(scene.renderer, "materials/stone.json"),
					"street": GLMaterial.load(scene.renderer, "materials/street.json"),
					"error": GLMaterial.load(scene.renderer, "materials/error.json"),
					"grass": GLMaterial.load(scene.renderer, "materials/grass.json"),
					];

		random = new Random();
		
		addMesh(floor[0], materials["grass"], vec3(-5, 0, -5));
		addStone(stone[1], materials["stone"], vec3(-110, 0, -20));
		addStone(stone[1], materials["stone"], vec3(-120, 0, -30));
		addStone(stone[0], materials["stone"], vec3(-130, 0, -10));
		addStone(stone[1], materials["stone"], vec3(-150, 0, -50));
		addStone(stone[1], materials["stone"], vec3(-200, 0, 10));
		addStone(stone[1], materials["stone"], vec3(-130, 0, 20));
		addStone(stone[1], materials["stone"], vec3(-140, 0, -30));
		
		for(int x = -40; x < -10; x++)
			addMesh(street[0], materials["street"], vec3(x * 10, 0, 0));

		save();
		load("save0_auto");
	}

	private void load(string save)
	{
		Level* level = new Level("saves/" ~ save ~ ".json");
		

		for(int i = 0; i < level.blocks.length; i++)
		{
			addMesh(meshes[level.blocks[i].model][level.blocks[i].modelID], materials[level.blocks[i].material], vec3(level.blocks[i].position.x * level.blockX, 0, level.blocks[i].position.z * level.blockY), level.blocks[i].rotation);
		}
	}

	private void save()
	{
		Level level;
		level.name = "Bob";
		level.width = 20;
		level.height = 20;
		level.blockX = 10;
		level.blockY = 10;

		Block block;
		block.model = "street";
		block.modelID = 0;
		block.material = "street";
		block.rotation = vec3(0, 0, 0);
		block.position = vec3(10, 0, 11);

		level.blocks ~= block;

		level.save("saves/save0_auto.json");
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
}

class GameScene : Scene
{
	override void init()
	{
		addLayer(new Game3DLayer());
	}
}