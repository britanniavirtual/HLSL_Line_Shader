///////////////////////////////////////////////////
// Simple point-to-point line shader
///////////////////////////////////////////////////

//Standard matrix buffer
cbuffer MatrixBuffer : register(b7)
{
	matrix worldMatrix;
	matrix viewMatrix;
	matrix projectionMatrix;
};

cbuffer CameraBuffer : register(b1)// From ::CameraMatrixBuffer in the cpp
{
    float3 cameraPosition;
    float padding;
};

//For setting per-object color and width
cbuffer objectData : register(b2)
{
	float4 mainColor;
	float4 thickness;//Line thickness
};

struct VertexIn3
{
	float3 head : POSITION0;
	float3 tail : POSITION1;
};

struct VertexOut2
{
	float3 head : POSITION2;
	float3 tail : POSITION3;
};

//[Vertex shader]
VertexOut2 VS(VertexIn3 input)
{
	VertexOut2 output;

	output.head.x = input.head.x;
	output.head.y = input.head.y;
	output.head.z = input.head.z;

	
	output.tail.x = input.tail.x;
	output.tail.y = input.tail.y;
	output.tail.z = input.tail.z;

	return output;
}

struct GS_OUTPUT
{
	float4 Pos : SV_POSITION;
};

struct GeoOut
{
	float4 PosH   : SV_POSITION;
};

//[Geo shader]
[maxvertexcount(4)]
void GS(point VertexOut2 input[1], inout TriangleStream<GeoOut> OutputStream)
{
	//[Strand width]
	float strandWidth1 = thickness.x;
	float strandWidth2 = thickness.x;

	float3 pos1;
	pos1.x = input[0].head.x;
	pos1.y = input[0].head.y;
	pos1.z = input[0].head.z;

	float3 pos2;
	pos2.x = input[0].tail.x;
	pos2.y = input[0].tail.y;
	pos2.z = input[0].tail.z;

	float3 tangent = pos2.xyz - pos1.xyz;
	tangent = normalize(tangent);

	float3 eyeVec = mul(cameraPosition, worldMatrix) - pos1;
	float3 sideVec = normalize(cross(eyeVec, tangent));

	float3 width1 = sideVec * strandWidth1;
	float3 width2 = sideVec * strandWidth2;

	float4 pos11 = float4( pos1.xyz + width1, 1 );
	float4 pos12 = float4( pos1.xyz - width1, 1 );
	float4 pos21 = float4( pos2.xyz + width2, 1 );
	float4 pos22 = float4( pos2.xyz - width2, 1 );


	float4x4 worldViewProj = mul(worldMatrix, mul(viewMatrix, projectionMatrix));

	GeoOut gout1;
	gout1.PosH = mul(pos11, worldViewProj);//v1;
	OutputStream.Append(gout1);
	
	GeoOut gout2;
	gout2.PosH = mul(pos12, worldViewProj);//v2;
	OutputStream.Append(gout2);
	
	GeoOut gout3;
	gout3.PosH = mul(pos21, worldViewProj);//v3;
	OutputStream.Append(gout3);

	GeoOut gout4;
	gout4.PosH = mul(pos22, worldViewProj);//v3;
	OutputStream.Append(gout4);
}


//[Pixel shader]
float4 PS(GeoOut input) : SV_TARGET
{
	float4 textureDiffuse;
	textureDiffuse.x = mainColor.x;
	textureDiffuse.y = mainColor.y;
	textureDiffuse.z = mainColor.z;
	textureDiffuse.w = 1.0;
	return textureDiffuse;
}
