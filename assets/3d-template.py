# 3D 插入镜头模板（Blender headless / EEVEE / 手机 proot 可用）
# 用法：blender -b --python 3d-template.py -- --out /sdcard/.../frames --frames 90 --fps 25
# 输出：PNG 序列（1080x1080 或自定义），后续用 ffmpeg 合成
import bpy, math, sys, os, argparse

argv = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
ap = argparse.ArgumentParser()
ap.add_argument('--out', default='/tmp/3d_frames')
ap.add_argument('--frames', type=int, default=75)
ap.add_argument('--fps', type=int, default=25)
ap.add_argument('--size', type=int, default=1080)
a = ap.parse_args(argv)
os.makedirs(a.out, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = 'BLENDER_EEVEE'
sc.render.resolution_x = a.size; sc.render.resolution_y = a.size
sc.render.fps = a.fps; sc.frame_start = 1; sc.frame_end = a.frames
sc.eevee.taa_render_samples = 8
sc.render.image_settings.file_format = 'PNG'
sc.render.filepath = os.path.join(a.out, 'f')

# 暖白背景
w = bpy.data.worlds.new('W'); sc.world = w; w.use_nodes = True
w.node_tree.nodes['Background'].inputs[0].default_value = (0.85, 0.84, 0.82, 1)

def mat(name, rgb, rough=0.3):
    m = bpy.data.materials.new(name); m.use_nodes = True
    p = m.node_tree.nodes['Principled BSDF']
    p.inputs['Base Color'].default_value = (*rgb, 1); p.inputs['Roughness'].default_value = rough
    return m
WHITE = mat('white', (0.95, 0.94, 0.92), 0.25)
GREY  = mat('grey', (0.82, 0.81, 0.79), 0.35)
RED   = mat('red', (0.78, 0.18, 0.15), 0.3)

def card(size, pos, rot, m):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos, rotation=rot)
    o = bpy.context.object
    o.scale = (size, size*0.02, size*0.63)
    b = o.modifiers.new('b','BEVEL'); b.width=0.04; b.segments=3
    o.data.materials.append(m); return o

card(1.8, (-1.6, 0.3, 0.2), (math.radians(-12), math.radians(18), 0), WHITE)
card(1.4, (0.4, -0.4, -0.2), (math.radians(-8), math.radians(-14), 0), GREY)
card(0.9, (2.0, 0.5, 0.7), (math.radians(-16), math.radians(24), 0), WHITE)
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.22, location=(1.1, 0.9, 0.9)); bpy.context.object.data.materials.append(RED)
bpy.ops.object.shade_smooth()

bpy.ops.object.camera_add(location=(0,-4.6,1.9))
cam = bpy.context.object; sc.camera = cam; cam.data.lens = 60
from mathutils import Vector
cam.rotation_euler = (Vector((0,0,0.1))-cam.location).to_track_quat('-Z','Y').to_euler()

bpy.ops.object.light_add(type='AREA', location=(-2.2,-2.4,3.2)); bpy.context.object.data.energy=900; bpy.context.object.data.size=2.5
bpy.ops.object.light_add(type='AREA', location=(2.6,-1.2,2.4)); bpy.context.object.data.energy=300; bpy.context.object.data.size=3
bpy.ops.object.light_add(type='SUN', location=(0,-3,4), rotation=(math.radians(35),math.radians(10),0)); bpy.context.object.data.energy=2.5

# 相机推进
cam.location = (0,-4.6,1.9); cam.keyframe_insert('location', frame=1)
cam.location = (0.15,-3.9,1.75); cam.keyframe_insert('location', frame=a.frames)
for fc in cam.animation_data.action.fcurves:
    for kp in fc.keyframe_points: kp.interpolation='LINEAR'

bpy.ops.render.render(animation=True)
print('3D_TEMPLATE_DONE', a.out)
