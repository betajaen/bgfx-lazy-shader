# BGFX Lazy Shader

This is a small Ruby script that will convert and compile 'lazy shader' files into the [BGFX library ](https://github.com/bkaradzic/bgfx)shader format. The lazy shader format is a shorthand format, where it takes the Unity Engine approach where the fragment and vertex shaders are in a single file.

```glsl
vec3 a_position : POSITION;
vec4 a_color0 : COLOR0;

#include "common.sh"

void vertex()
{
	gl_Position = mul(u_modelViewProj, vec4(a_position, 1.0) );
	v_color0 = a_color0;
}

vec4 v_color0 : COLOR0 = vec4(1.0, 0.0, 0.0, 1.0);

void fragment()
{
	gl_FragColor = v_color0;   
}
```

Lazy Shader will automatically rewrite the shader functions into seperate vertex and fragment files, and figure out the used attributes and vertex information passed to the fragment shader.

```glsl
vec3 a_position : POSITION;
vec4 a_color0 : COLOR0;
vec4 v_color0 : COLOR0 = vec4(1.0, 0.0, 0.0, 1.0);
```
```glsl
$input a_position, a_color0
$output v_color0

#include "common.sh"

void main()
{
	gl_Position = mul(u_modelViewProj, vec4(a_position, 1.0) );
	v_color0 = a_color0;
}
```
```glsl
$input v_color0

#include "common.sh"

void main()
{
	gl_FragColor = v_color0;   
}
```

## Installation

You will need to install Ruby (~2.3.0) on your computer. You will also need to install the [filewatcher](https://github.com/thomasfl/filewatcher) gem, via `gem install filewatcher`. You should copy the bgfx `shaderc.exe` program into the same folder. You should create an `out` folder, and place any shader includes you use in there

## Usage

Lazy Shader can work in two modes, as a command-line utility tool, or as a running process that watches a directory for changes to '.shader' files and then convert them automatically. Additionally, it can open a UDP Socket and send a UDP packet with the name of the shader, to for example; reload the shader, to work on it live.

```
lazy_shader -f cubes.shader
```

```
lazy_shader -a
```

### Switches

* `-a` -- 'Automatic mode', watch a directory for changes to shaders and recompile.
* `-f` -- 'File mode', process a shader file
* `-u` -- 'UDP', Open a UDP socket and send a packet with the name of the shader
* `--no-compile` -- Just convert, don't compile.

## Lazy Format

The attribute and vertex output format is specified in the shader;

```glsl
vec4 a_color0 : COLOR0;
vec4 v_color0 : COLOR0 = vec4(1.0, 0.0, 0.0, 1.0);
```

These can be anywhere in the shader, as long as they are outside function blocks. `$input` and `$output` are automatically filled out, as long as they match the `v_name`, `a_name` pattern.

`#includes` are noted for both types of shaders, so you only need to include them once.

The lazy format assumes that the vertex shader is given first; so any uniforms, functions, etc. are copied into the vertex shader. Once, the vertex block; `void vertex()` has finished, the fragment shader is assumed and likewise uniforms, functions, etc. are copied into that.


## Configuration

Configuration is done via editing the ruby file itself, the configuration information is at the top.

* `Targets` -- shaderc switch information and naming schemes for various shader targets; GLSL, DX9 and DX11.
* `ShaderExtension` -- `.shader` extension name.
* `TargetPath` -- Output path for converted and compiled shaders.
* `CompileTargets` -- What targets to compile for.
* `UDPPort` -- UDP Port to communicate on
* `UDPAddress` -- UDP Address to communicate to

## UDP

With the UDP option enabled. It will emit a character string with the name of the shader (without the `.shader` extension), the length of the packet is the number of characters in the string. In automatic mode, it will emit the a UDP packet foreach time the shader is re-built, in file mode, it will be just the once.

## License

```     
Lazy Shader

Copyright (c) 2016 Robin Southern                                             
                                                                                
Permission is hereby granted, free of charge, to any person obtaining a copy  
of this software and associated documentation files (the "Software"), to deal 
in the Software without restriction, including without limitation the rights  
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell     
copies of the Software, and to permit persons to whom the Software is         
furnished to do so, subject to the following conditions:                      
                                                                                
The above copyright notice and this permission notice shall be included in    
all copies or substantial portions of the Software.                           
                                                                                
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,      
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER        
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN     
THE SOFTWARE.
```
