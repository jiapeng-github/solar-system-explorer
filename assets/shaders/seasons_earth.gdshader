shader_type canvas_item;
uniform sampler2D surface_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D clouds : source_color, filter_linear_mipmap, repeat_enable;
uniform float tilt = 0.4084;
uniform float phase = 0.0;
void fragment(){
 vec2 p=UV*2.0-1.0;
 float rr=dot(p,p);
 if(rr>1.0){COLOR=vec4(0.0);}else{
  vec3 n=vec3(p.x,-p.y,sqrt(1.0-rr));
  // Fixed observer above orbital plane; axial direction is constant in inertial space.
  vec3 world=vec3(n.x,.8660254*n.y+.5*n.z,-.5*n.y+.8660254*n.z);
  vec3 local=vec3(cos(tilt)*world.x-sin(tilt)*world.y,sin(tilt)*world.x+cos(tilt)*world.y,world.z);
  vec2 uv=vec2(atan(local.x,local.z)/6.2831853+.5,acos(clamp(local.y,-1.0,1.0))/3.14159265);
  vec3 color=texture(surface_map,uv).rgb;
  float cloud=smoothstep(.22,.85,texture(clouds,uv).r);
  color=mix(color*1.2,vec3(.9,.96,1.0),cloud*.72);
  float light=smoothstep(-.06,.7,dot(world,vec3(sin(phase),0.0,cos(phase))));
  color*=.36+.72*light;
  color*=.78+.22*n.z;
  color+=vec3(.012,.045,.095)*(.3+.7*light);
  color+=vec3(.03,.42,.8)*pow(1.0-n.z,3.0)*(.35+.65*light);
  COLOR=vec4(color,1.0-smoothstep(.97,1.0,rr));
 }
}
