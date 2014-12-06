module GameScene;

import EncoShared;
import EncoDesktop;
import EncoGL3;

import std.file;

enum MAT_HOUSEL1 = 0;
enum MAT_TRAILER1 = 1;

class Game3DLayer : RenderLayer
{
	override void init(Scene scene)
	{
		auto floor = Mesh.loadFromObj("meshes/floor.obj", 0);
		auto houses_low = Mesh.loadFromObj("meshes/houses_low.obj", 0);

		materials = [
					GLMaterial.load(scene.renderer, "materials/houseL1.json"),
					GLMaterial.load(scene.renderer, "materials/trailer1.json"),
					];

		random = new Random();
		
		addGameObject(new MeshObject(floor[0], GLMaterial.load(scene.renderer, "materials/grass.json")));
		
		for(int x = -10; x < 10; x++)
		{
			for(int y = -10; y < 10; y++)
			{
				int type = random.nextInt(2);
				addTrailer(houses_low[type], materials[type], vec3(x * 10 + 5, 0, y * 10 + 5));
			}
		}
	}

	private void save()
	{
		ubyte[] data;

		write("saves/save", data);
	}

	private void addMesh(Mesh mesh, Material material, vec3 position)
	{
		auto obj = new MeshObject(mesh, material);
		obj.transform.position = position;
		addGameObject(obj);
	}

	private void addTrailer(Mesh mesh, Material material, vec3 position)
	{
		auto obj = new MeshObject(mesh, material);
		obj.transform.position = position;
		obj.transform.rotation.y = (random.nextFloat() - 0.5f) * 0.2f;
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