shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;
uniform bool portrait_light = false;
varying vec3 world_pos;
varying vec3 center;
void vertex(){
 world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 center=MODEL_MATRIX[3].xyz;
}
void fragment(){
 float bands=.86+.08*sin(UV.x*120.0)+.035*sin(UV.x*235.0);
 float gap=1.0-.94*exp(-pow((UV.x-.63)*55.0,2.0));
 float edge=smoothstep(0.0,.035,UV.x)*(1.0-smoothstep(.94,1.0,UV.x));
 vec3 light_dir=normalize(-center+vec3(.0001));
 if(portrait_light){light_dir=normalize((INV_VIEW_MATRIX*vec4(-.65,.5,.85,0.0)).xyz);}
 vec3 relative=world_pos-center;
 float behind=dot(relative,light_dir);
 float separation=length(relative-light_dir*behind)/max(length(relative),.001);
 float shadow=mix(1.0,smoothstep(.35,.58,separation),step(behind,0.0));
 ALBEDO=mix(vec3(.52,.44,.33),vec3(.82,.75,.60),bands)*(.3+.7*shadow);
 ALPHA=edge*gap*.94;
}
