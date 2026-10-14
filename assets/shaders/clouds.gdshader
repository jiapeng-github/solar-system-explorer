shader_type spatial;
render_mode unshaded, depth_draw_never;
uniform sampler2D cloud_map : filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool portrait_light = false;
varying vec3 world_normal;
varying vec3 world_position;
void vertex(){world_normal=MODEL_NORMAL_MATRIX*NORMAL;world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec3 light_dir=normalize(-world_position);
 if(portrait_light){light_dir=normalize((INV_VIEW_MATRIX*vec4(-.65,.5,.85,0.0)).xyz);}
 float light=smoothstep(-.13,.8,dot(normalize(world_normal),light_dir));
 float clouds=texture(cloud_map,UV).r;
 ALBEDO=vec3(.86,.92,1.0)*(.075+.925*light);
 ALPHA=smoothstep(.14,.88,clouds)*.93;
}
