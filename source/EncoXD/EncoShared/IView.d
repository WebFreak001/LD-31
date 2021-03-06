module Enco.Shared.IView;

import EncoShared;

abstract class IView
{
	abstract void create(IRenderer renderer);
	abstract void destroy();

	abstract bool update(f64 deltaTime);
	
	@property void size(u32vec2 size) { m_size = size; onResize(); }
	@property void name(string name) { m_name = name; onRename(); }
	
	@property u32vec2 size() { return m_size; }
	@property string name() { return m_name; }
	
	protected abstract void onResize();
	protected abstract void onRename();
	
	final @property u32 width() { return m_size.x; }
	final @property u32 height() { return m_size.y; }

	protected u32vec2 m_size;
	protected string m_name;
}