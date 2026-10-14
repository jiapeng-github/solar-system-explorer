shader_type canvas_item;
uniform sampler2D surface_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D clouds : filter_linear_mipmap, repeat_enable;
uniform bool earth = false;
uniform bool solar = false;
uniform bool polar = false;
uniform float rotation_angle = 0.0;
void fragment(){
 vec2 p=UV*2.0-1.0;
 float rr=dot(p,p);
 if(rr>1.0){COLOR=vec4(0.0);}else{
  float z=sqrt(max(0.0,1.0-rr));
  vec3 n=polar ? vec3(p.x,z,p.y) : vec3(p.x,-p.y,z);
  vec2 uv=vec2(atan(n.x,n.z)/6.2831853+.5-rotation_angle/6.2831853,acos(clamp(n.y,-1.0,1.0))/3.14159265);
  vec3 c=texture(surface_map,uv).rgb;
  if(earth){float cloud=smoothstep(.14,.88,texture(clouds,uv).r);c=mix(c,vec3(.88,.94,1.0),cloud*.65);}
  float light=polar ? smoothstep(-.04,.1,-p.x) : max(dot(normalize(vec3(-.5,.35,1.0)),vec3(p.x,-p.y,z)),0.0);
  c*=.10+.9*light;
  if(earth){c+=vec3(.04,.22,.48)*pow(1.0-z,4.0)*light;}
  if(solar){
   float grain=sin(uv.x*430.0+sin(uv.y*310.0)*3.0)*sin(uv.y*530.0+sin(uv.x*270.0));
   c=mix(vec3(1.0,.32,.015),vec3(1.0,.86,.3),.6+.25*grain)*(.7+.3*z);
  }
  COLOR=vec4(c,1.0-smoothstep(.985,1.0,rr));
 }
}
