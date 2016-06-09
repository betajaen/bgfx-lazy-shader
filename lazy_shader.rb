# BGFX Lazy Shader
# 
# Copyright (c) 2016 Robin Southern                                             
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy  
# of this software and associated documentation files (the "Software"), to deal 
# in the Software without restriction, including without limitation the rights  
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell     
# copies of the Software, and to permit persons to whom the Software is         
# furnished to do so, subject to the following conditions:                      
# 
# The above copyright notice and this permission notice shall be included in    
# all copies or substantial portions of the Software.                           
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,      
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER        
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN     
# THE SOFTWARE.

Targets = {
    :dx9 => {
        :vertex   => '--platform windows -p vs_3_0 -O 3 --type vertex',
        :fragment => '--platform windows -p ps_3_0 -O 3 --type fragment',
        :prefix   => { :vertex => 'vs_', :fragment => 'fs_' },
        :suffix   => { :vertex => '.dx9.bin', :fragment => '.dx9.bin' }
    },
    :dx11 => {
        :vertex   => '--platform windows -p vs_4_0 -O 3 --type vertex',
        :fragment => '--platform windows -p ps_4_0 -O 3 --type fragment',
        :prefix   => { :vertex => 'vs_', :fragment => 'fs_' },
        :suffix   => { :vertex => '.dx11.bin', :fragment => '.dx11.bin' }
    },
    :glsl => {
        :vertex   => '--platform linux -p 120 --type vertex',
        :fragment => '--platform linux -p 120  --type fragment',
        :prefix   => { :vertex => 'vs_', :fragment => 'fs_' },
        :suffix   => { :vertex => '.glsl.bin', :fragment => '.glsl.bin' }
    }
}

# Extension of the shader
ShaderExtension = '.shader'

# Where to write the shaders
TargetPath = 'out/'

# What targets should the shaders be compiled to
CompileTargets = [ :dx9, :dx11, :glsl ]

# Relative file path to the compiler
ShaderCompilerPath = 'shaderc.exe'

# UDP Port
UDPPort = 15551

# UDP Address
UDPAddress = "127.0.0.1"

########################################################################################

require 'optparse'
require 'filewatcher'
require 'socket'

def scanAdd(q, l, r)
    q.push l.scan(r).flatten
end

def finalise(q)
    q.flatten!
    q.uniq!
end

def build_varying(a, v)
    src = String.new
    src << a.join("\n") << "\n"
    src << v.join("\n") << "\n"
    return src
end

def build_vertex(s, a, v, i)
    src = String.new

    src << '$input ' << a.join(', ') << "\n"
    src << '$output ' << v.join(', ') << "\n"
    src << "\n"

    i.each do |inc|
        src << '#include ' + inc + "\n"
    end

    src << "\n"
    src << s

    return src
end

def build_fragment(s, v, i)
    src = String.new

    src << '$input ' << v.join(', ') << "\n"

    src << "\n"
    i.each do |inc|
        src << '#include ' + inc + "\n"
    end

    src << "\n"
    src << s

    return src
end

def make_shader(file)

    name = file.sub(ShaderExtension, '')

    kAttr_Regex = /\W(a_\w+)/
    kVertex_Regex = /\W(v_\w+)/
    kInclude_Regex = /#include\s+(.+)/
    kVaryingVertex = /^\s*(\w+\s+v_\w+.*)/
    kVaryingAttribute = /^\s*(\w+\s+a_\w+.*)/

    varying_attributes = []
    varying_vertex = []
    attributes = []
    vertexs = []
    includes = []
    src_text = File.read(file)
    vertex_src = ""
    fragment_src = ""

    src_text.each_line do |line|
        scanAdd(varying_attributes, line, kVaryingAttribute)
        scanAdd(varying_vertex, line, kVaryingVertex)
        scanAdd(attributes, line, kAttr_Regex)
        scanAdd(vertexs, line, kVertex_Regex)
        scanAdd(includes, line, kInclude_Regex)
    end

    finalise(attributes)
    finalise(vertexs)
    finalise(includes)
    finalise(varying_attributes)
    finalise(varying_vertex)

    mode = -1
    braces = 0

    src_text.each_line do |c|

        braces += c.count '{'
        braces -= c.count '}'
        
        # Skip includes
        next if c =~ /#include\s+.+/

        # Skip varyings (if they are outside braces)
        if (braces == 0)
            next if c =~ /^\s*\w+\s+v_\w+/
            next if c =~ /^\s*\w+\s+a_\w+/
        end

        if (mode == -1 && braces == 0 && c =~ /\W?void\s+vertex()/)
            vertex_src << c.gsub(/\W?void(\s+)vertex\(\)/, 'void\1main()')
            mode = 1
            next
        end

        if (braces == 0 && mode == 1)
            vertex_src << c
            mode = -2
            next
        end

        if (mode == -2 && braces == 0 && c =~ /\W?void\s+fragment()/)
            fragment_src << c.gsub(/\W?void(\s+)fragment\(\)/, 'void\1main()')
            mode = 2
            next
        end

        if (braces == 0 && mode == 2)
            fragment_src << c
            mode = 0
            next
        end

        if mode == 1 || mode == -1
            vertex_src << c
        end

        if mode == 2 || mode == -2
            fragment_src << c
        end
    end

    varying_path  = TargetPath + name + '_varying.def.sc'
    vertex_path   = TargetPath + 'vs_' + name + '.sc'
    fragment_path = TargetPath + 'fs_' + name + '.sc'

    File.write(varying_path, build_varying(varying_attributes, varying_vertex))
    File.write(vertex_path, build_vertex(vertex_src, attributes, vertexs, includes))
    File.write(fragment_path, build_fragment(fragment_src, vertexs, includes))

    puts "Coverted #{name}."
end

def compile_shader(src, dst, varying, args)
    cmd = ShaderCompilerPath + ' -f ' + src + ' -o ' + dst + ' --varyingdef ' + varying + ' ' + args
    #  puts cmd
    `#{cmd}`
    r = ($?.exitstatus != 0)
    if (r)
        puts "#{src}"
    end
    r
end

def compile_shaders(file, target, target_name)
    name = file.sub(ShaderExtension, '')

    varying_src_path  = TargetPath + name + '_varying.def.sc'
    vertex_src_path   = TargetPath + 'vs_' + name + '.sc'
    fragment_src_path = TargetPath + 'fs_' + name + '.sc'

    vertex_dst_path   = TargetPath + target[:prefix][:vertex] + name + target[:suffix][:vertex]
    fragment_dst_path = TargetPath + target[:prefix][:fragment] + name + target[:suffix][:fragment]

    return false if compile_shader(vertex_src_path, vertex_dst_path, varying_src_path, target[:vertex]);   
    return false if compile_shader(fragment_src_path, fragment_dst_path, varying_src_path, target[:fragment]);

    puts "Compiled #{name} for #{target_name}"

    return true
end

def emit_udp(s, f)
    name = f.sub(ShaderExtension, '')
    s.send "#{name}", 0, UDPAddress, UDPPort
end

def process_file(options, socket)
    f = options[:file]
    
    make_shader(f)

    if (options[:compile])
        CompileTargets.each do |target|
            break if (!compile_shaders(f, Targets[target], target))
        end
    end

    if (options[:udp])
        socket = UDPSocket.new if socket == nil
        emit_udp(socket, f)
    end
end

options = {}
options[:compile] = true

OptionParser.new do |opts|
  opts.banner = "Usage: lazy_shader.rb [options]"

  opts.on("-f", "--file FILE", "'#{ShaderExtension}' file to process") do |v|
    options[:file] = v
  end
  
  opts.on("-a", "--auto", "Automatic mode. Listen to shader files in current working directory, and automatically recompile") do |v|
    options[:auto] = v
  end

  opts.on("-u", "--udp", "Send a UDP packet to port #{UDPPort} to localhost with the shader name.") do |v|
    options[:udp] = v
  end

  opts.on("-c", "--[no-]compile", "Compile after building. Default: true") do |v|
    options[:compile] = v
  end
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

s = (options[:udp] ? UDPSocket.new : nil)

if (options[:file] != nil)
    process_file(options, s)
elsif (options[:auto])
    FileWatcher.new("*#{ShaderExtension}").watch do |filename|
       options[:file] = filename
       process_file(options, s)
    end
end
