#version 330 core
out vec4 FragColor;

in vec3 oColor;
in vec2 texCoord;

uniform sampler2D tex;

void main()
{
    vec4 tmpTex = texture(tex, texCoord);
    tmpTex.g = tmpTex.r;
    tmpTex.b = tmpTex.r;
    FragColor = tmpTex * vec4(oColor, 1.0) * 10;
}