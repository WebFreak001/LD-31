module ParticleSystem;

import EncoShared;
import std.algorithm;

struct Particle
{
	vec3 position;
	vec3 positionDelta;
	vec3 scale;
	vec3 scaleDelta;
	vec3 rotation;
	vec3 rotationDelta;
	float time = 0;

	ParticleMesh object;
}

class ParticleMesh : MeshObject
{
	this(Mesh mesh, Material material)
	{
		super(mesh, material);
	}

	override protected void draw(RenderContext context, IRenderer renderer)
	{
		if(m_mesh.renderable is null)
		{
			m_mesh = renderer.createMesh(m_mesh);
		}

		if(!inited)
		{
			m_material.program.registerUniform("time");
			inited = true;
		}

		m_material.bind(context);
		
		m_material.program.set("time", time);
		m_material.program.set("modelview", context.camera.viewMatrix * modelMatrix);
		m_material.program.set("projection", context.camera.projectionMatrix);
		m_material.program.set("normalmatrix", modelMatrix().transposed().inverse());

		renderer.renderMesh(m_mesh);
	}

	bool inited = false;
	float time;
}

class ParticleSystem : GameObject
{
	Particle[] particles;

	vec3[] emitters;

	Mesh mesh;
	Material mat;

	Random random;
	
	this(int max = 1000)
	{
		random = new Random();
		particles = new Particle[max];
	}

	void addEmitter(vec3 pos)
	{
		emitters.length++;
		emitters[emitters.length - 1] = pos;
	}

	void add(Particle particle)
	{
		for(int i = 0; i < particles.length; i++)
		{
			if(particles[i].time >= 1 || particles[i].object is null)
			{
				particle.time = 0;
				particles[i] = particle;
				return;
			}
		}
	}

	override protected void draw(RenderContext context, IRenderer renderer)
	{
		if(emitters.length > 0)
		foreach(vec3 emitter; emitters)
		{
			if(random.nextFloat() < 0.3f)
				add(Particle(emitter, vec3(random.nextFloat() - 0.5f, 3.0f, random.nextFloat() - 0.5f) * 0.05f, vec3(0), vec3(0.02f, 0.02f, 0.02f), vec3(0), vec3(0), 0, new ParticleMesh(mesh, mat)));
		}

		foreach(int i, Particle p; particles)
		{
			if(p.time < 1 && p.object !is null)
			{
				p.position += p.positionDelta;
				p.scale += p.scaleDelta;
				p.rotation += p.rotationDelta;
				
				p.object.time = p.time;
				p.object.transform.position = p.position;
				p.object.transform.rotation = p.rotation;
				p.object.transform.scale = p.scale;
				p.object.performDraw(context, renderer);
				p.time += 0.01f;
				particles[i] = p;
			}
		}
	}
	
}