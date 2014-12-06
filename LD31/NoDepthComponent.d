module NoDepthComponent;

import EncoShared;
import EncoGL3;

class NoDepthComponent : IComponent
{
	override void preDraw(RenderContext context, IRenderer renderer)
	{
		glDisable(GL_DEPTH_TEST);
	}
	
	override void draw(RenderContext context, IRenderer renderer)
	{
		glEnable(GL_DEPTH_TEST);
	}

	override void add(GameObject object) {}
	
	override void preUpdate(f64 deltaTime) {}
	
	override void update(f64 deltaTime) {}
}