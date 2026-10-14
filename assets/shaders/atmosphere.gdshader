shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;
uniform bool portrait_light = false;
varying vec3 world_position;
varying vec3 world_normal;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;world_normal=MODEL_NORMAL_MATRIX*NORMAL;}
void fragment(){
 vec3 n=normalize(world_normal);
 vec3 v=normalize(CAMERA_POSITION_WORLD-world_position);
 vec3 light_dir=normalize(-world_position);
 if(portrait_light){light_dir=normalize((INV_VIEW_MATRIX*vec4(-.65,.5,.85,0.0)).xyz);}
 float rim=pow(clamp(1.0-abs(dot(n,v)),0.0,1.0),3.5);
 ALBEDO=vec3(.10,.44,.95);
 ALPHA=rim*.8*smoothstep(-.45,.65,dot(n,light_dir));
}
