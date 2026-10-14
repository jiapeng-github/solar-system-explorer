shader_type canvas_item;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 vec2 p=(UV*2.0-1.0)*1.9;
 float r=length(p);
 float halo=exp(-max(r-1.0,0.0)*3.7)*.5;
 float rays=.8+.2*noise(vec2(atan(p.y,p.x)*31.0,r*2.0));
 vec3 color=vec3(1.0,.68,.18);
 float alpha=halo*smoothstep(1.9,1.0,r)*rays;
 if(r<1.0){
  float z=sqrt(1.0-r*r);
  vec2 q=p*10.0+vec2(noise(p*5.0),noise(p*5.0+9.0))*2.0;
  float n=noise(q)*.50+noise(q*2.3)*.3+noise(q*5.2)*.2;
  float veins=pow(1.0-abs(noise(q*1.8)*2.0-1.0),9.0);
  color=mix(vec3(1.0,.38,.035),vec3(1.0,.86,.30),n);
  color+=vec3(.1,.20,.13)*veins;
  color*=.80+.20*z;
  color+=vec3(.20,.38,.24)*pow(r,24.0);
  alpha=1.0;
 }
 COLOR=vec4(color,alpha);
}
