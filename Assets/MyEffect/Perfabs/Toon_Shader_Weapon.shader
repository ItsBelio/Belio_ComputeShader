Shader "Toon_Shader_Weapon"
{
	Properties
	{
		[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2  //�����ⲿ���ƿ���
		[Header(Diffuse)]
		_DiffuseTex("Diffuse Tex", 2D) = "white" {}
		_MaskTex("Mask Tex", 2D) = "white" {}
		_LightOrDark("Dark or Light",range(0,1))=1
		_TintColor1("Dark Tint Color",Color)=(1.0,1.0,1.0,1.0)
		_TintColor2("Light Tint Color",Color) = (1.0,1.0,1.0,1.0)
		[Header(Spec)]
		_MetalIntensity1("Spec Intensity",float) = 1
		_MetalIntensity2("Metal Intensity",float) = 1
		_MeatlSize("Meatl Size",Range(0,1)) = 0.8
		[Header(Emission)]
		_EmissionIntensity("Emission Intensity",float) = 1
		_EmissionSpeed("Emission Speed",range(0,1)) = 1
		_EmissionColor("Emission Color",color)=(0,0,0,0)
		[Header(RimLight)]
		
		_FresnelMin("Fresnel Min",range(0,1)) = 1
		_FresnelMax("Fresnel Max",range(0,1)) = 1
		_FresnelIntensity("Fresnel Intensity",float) = 1
		
		[Header(OutLine)]
		_OutLineWidth("OutLine Width",float) = 1
		_OutLineColor("OutLine Color",color) = (0,0,0,0)

		[Header(Disolve)]
		_DisolveEmissColor("DisolveEmissColor",COLOR)=(1,1,1,1)
		_DissolveAmount("Dissolve Amount",float)=0
		_DissolveOffset("Dissolve Offset",float)=0
		_DissolveHardness("Dissolve Hardness",float)=1
		_DissolveEmissIntensity("DissolveEmissIntensity",float)=1

		_GrainTex("Grain Tex",2D)="White"{}
		_GrainFalloff("Grain Falloff",float)=1
		_GrainTiling("Grain Tilling",vector)=(1,1,1,1)
		_GrainIntensity("Grain Intensity",float)=1

		_DissolveTex("Dissolve Tex",2D)="White"{}
		_DissolveTexFalloff("DissolveTex Falloff",float)=1
		_DissolveTexTiling("DissolveTex Tiling",vector)=(1,1,1,1)

		_DissolveAmount2("Dissolve Amount 2",Range(0,1))=0
		_DissolveOffset2("Dissolve Offset 2",float)=0
		_DissolveSoftNess("Dissolve Softness",float)=1
		_DissolveEmissIntensity2("DissolveEmissIntensity 2",float)=1

		_TotalEmissIntensity("Total Emission",float)=1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue" = "Transparent" "IsEmissive" = "true" }
		ZWrite On
		Blend SrcAlpha OneMinusSrcAlpha
		Cull[_Cull] 
		
		Pass
		{
			Tags{"LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			struct Data
			{
				float4x4 TRS;
				float RotSpeed;
				float YMoveSpeed;
				float fadeSet;
			};

			StructuredBuffer<Data> input;
			float4x4 rotateZ(float a){
				return float4x4(cos(a),-sin(a),0,0 ,
				sin(a) ,cos(a),0,0 ,
				0,0,1,0 ,
				0,0,0,1);
			}

			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float3 normal:normal;
				float4 tangent:tangent;
				float4 color:color;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 Pos_World:TEXCOORD1;
				float3 normal_World:TEXCOORD2;
				float4 Pos_Model:TEXCOORD3;
				float fadeset:TEXCOORD4;
			};

			v2f vert (appdata v,uint index:SV_INSTANCEID)
			{
				v2f o;
				o.pos=mul(rotateZ(_Time.y*input[index].RotSpeed),v.vertex);
				o.pos=mul(input[index].TRS,o.pos);
				o.pos+=float4(0,1,0,0)*sin(_Time.y*input[index].YMoveSpeed);
				o.pos = UnityObjectToClipPos(o.pos);
				o.Pos_World = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.normal_World = UnityObjectToWorldNormal(v.normal);
				o.uv = v.texcoord;
				o.Pos_Model=v.vertex;
				o.fadeset=input[index].fadeSet;
				return o;
			}

			sampler2D _DiffuseTex;
			sampler2D _MaskTex;
			float4 _TintColor1;
			float4 _TintColor2;
			float _LightOrDark;

			float _MetalIntensity1;
			float _MeatlSize;
			float _MetalIntensity2;

			float _EmissionIntensity;
			float _EmissionSpeed;
			float4 _EmissionColor;

			float _FresnelMin;
			float _FresnelMax;
			float _FresnelIntensity;

			float4 _DisolveEmissColor;
			float _DissolveAmount;
			float _DissolveOffset;
			float _DissolveHardness;
			float _DissolveEmissIntensity;
			sampler2D _GrainTex;
			float _GrainFalloff;
			float4 _GrainTiling;
			float _GrainIntensity;
			sampler2D _DissolveTex;
			float _DissolveTexFalloff;
			float4 _DissolveTexTiling;
			float _DissolveAmount2;
			float _DissolveOffset2;
			float _DissolveSoftNess;
			float _DissolveEmissIntensity2;

			float _TotalEmissIntensity;

			float4 Triplanar( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling)
			{
				float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
				projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
				float3 nsign = sign( worldNormal );
				half4 xNorm; half4 yNorm; half4 zNorm;
				xNorm = tex2D( topTexMap, tiling * worldPos.zy * float2(  nsign.x, 1.0 ) );
				yNorm = tex2D( topTexMap, tiling * worldPos.xz * float2(  nsign.y, 1.0 ) );
				zNorm = tex2D( topTexMap, tiling * worldPos.xy * float2( -nsign.z, 1.0 ) );
				return xNorm * projNormal.x + yNorm * projNormal.y + zNorm * projNormal.z;
			}
			float Remap(float inputNumber,float MinOld,float MaxOld,float MinNew,Float MaxNew)
			{
				return (MinNew + (inputNumber - MinOld) * (MaxNew - MinNew) / (MaxOld - MinOld));
			}
			float SoftDissolve(float DissolveFactor,float DissolveAmount,float DissolveOffset,float DissolveSoftness)
			{
				float remap = Remap(DissolveAmount,0,1,0,DissolveOffset);
				return smoothstep(remap-DissolveSoftness,remap,DissolveFactor);
			}
			fixed4 frag (v2f i) : SV_Target
			{
				float3 normalDir = normalize(i.normal_World);
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.Pos_World);

				half4 BaseColor = tex2D(_DiffuseTex, i.uv);
				float NdotL = dot(normalDir, lightDir);
				float halfLambert = ((NdotL + 1) * 0.5);
				//ILM
				half4 ilm_map = tex2D(_MaskTex, i.uv);
				float spec_size = ilm_map.b;
				float spec_intensity = ilm_map.r;

				half3 final_diffuse = lerp(BaseColor*_TintColor1, BaseColor * _TintColor2, _LightOrDark);
				//Spec
				float Ks = 0.04;
				half3 H = normalize(lightDir + viewDir);
				float NdotH = dot(normalDir, H);
				float  SpecularPow = exp2(0.5 * spec_intensity * 11.0 + 2.0);
				float  SpecularNorm = (SpecularPow + 8.0) / 8.0;
				float3 SpecularColor = BaseColor * spec_size;
				float SpecularContrib = BaseColor * (SpecularNorm * pow(NdotH, SpecularPow));

				float MetalDir = normalize(mul(UNITY_MATRIX_V, normalDir));
				float MetalRadius = saturate(1 - MetalDir) * saturate(1 + MetalDir);
				float MetalFactor = saturate(step(0.5, MetalRadius) + 0.25) * 0.5 * saturate(step(0.15, MetalRadius) + 0.25) * lerp(_MetalIntensity2 * 5, _MetalIntensity2 * 10, spec_intensity);

				float3 MetalColor = MetalFactor * BaseColor * step(_MeatlSize, spec_intensity);
				float3 final_Spec = saturate(SpecularColor * (SpecularContrib  * NdotL* Ks + MetalColor)*halfLambert * _MetalIntensity1);
				//Emission
				float3 emission = BaseColor.a * _EmissionColor * _EmissionIntensity * abs((frac(_Time.y * _EmissionSpeed) - 0.5) * 2);

				//Fresnel
				half fresnel = 1.0 - dot(normalDir, viewDir);
				fresnel = smoothstep(_FresnelMin, _FresnelMax, fresnel);
				half3 final_env = fresnel * _FresnelIntensity * BaseColor.rgb;

				//Disolve
				float base1 = (i.Pos_Model.z-_DissolveAmount-_DissolveOffset)/_DissolveHardness;
				float dissolve_alpha=clamp(base1,0,1);
				float3 dissolve_color=(clamp(1-distance(base1,0.5),0,1)*_DisolveEmissColor*_DissolveEmissIntensity).rgb;

				float3 GrainColor=Triplanar(_GrainTex,i.Pos_World,i.normal_World,_GrainFalloff,_GrainTiling.xy).rgb;
				GrainColor*=_DisolveEmissColor*_GrainIntensity;

				float DissolveMapColor=Triplanar(_DissolveTex,i.Pos_World,i.normal_World,_DissolveTexFalloff,_DissolveTexTiling.xy).r;
				float dissolve_alpha2=SoftDissolve(DissolveMapColor,_DissolveAmount2,_DissolveOffset2,_DissolveSoftNess);

				float3 dissolve_color2=(1-distance(dissolve_alpha2,0.5)*2)*_DisolveEmissColor*_DissolveEmissIntensity2;
				
				float3 final_color = saturate(final_diffuse + final_Spec + final_env) + emission+dissolve_color+GrainColor+dissolve_color2+_DisolveEmissColor*_TotalEmissIntensity;
				return float4(final_color,dissolve_alpha * dissolve_alpha2*(sin(_Time.y*1.5*i.fadeset)*0.1+0.9));
			}
			ENDCG
		}
		Pass
		{
			Cull Front
			Tags { "RenderType"="Opaque" "Queue" = "Transparent" "IsEmissive" = "true" }
			ZWrite On
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_complie_fwdbase
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			struct Data
			{
				float4x4 TRS;
				float RotSpeed;
				float YMoveSpeed;
				float fadeSet;
			};

			StructuredBuffer<Data> input;
			float4x4 rotateZ(float a){
				return float4x4(cos(a),-sin(a),0,0 ,
				sin(a) ,cos(a),0,0 ,
				0,0,1,0 ,
				0,0,0,1);
			}

			struct appdata
			{
				float4 vertex : POSITION;
				float3 texcoord0 : TEXCOORD0;
				float3 normal:normal;
				float4 tangent : tangent;
				float4 color:color;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 Pos_Model:TEXCOORD1;
				float fadeset:TEXCOORD2;
			};


			sampler2D _BaseMap;
			float _OutLineWidth;
			float4 _OutLineColor;
			float _DissolveAmount;
			float _DissolveOffset;
			float _DissolveHardness;

			v2f vert(appdata v,uint index:SV_INSTANCEID)
			{
				v2f o;
				o.Pos_Model=v.vertex;
				v.vertex+=v.tangent*_OutLineWidth * 0.01 * v.color.a;
				v.vertex=mul(rotateZ(_Time.y*input[index].RotSpeed),v.vertex);
				v.vertex=mul(input[index].TRS,v.vertex);
				v.vertex+=float4(0,1,0,0)*sin(_Time.y*input[index].YMoveSpeed);
				o.pos=UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord0;
				o.fadeset=input[index].fadeSet;
				return o;
			}



			half4 frag(v2f i) : SV_Target
			{

				float base1 = (i.Pos_Model.z-_DissolveAmount-_DissolveOffset)/_DissolveHardness;
				float dissolve_alpha=clamp(base1,0,1);
				float3 basecolor = tex2D(_BaseMap,i.uv).rgb;
				half maxComponet = max(max(basecolor.r, basecolor.g), basecolor.b) - 0.004;
				half3 saturatedColor = step(maxComponet.rrr, basecolor)* basecolor;
				saturatedColor = lerp(basecolor.rgb, saturatedColor,0.6);
				half3 OutLineColor = 0.2 * saturatedColor * basecolor + 0.8 * _OutLineColor.rgb;

				return float4(OutLineColor,dissolve_alpha*(sin(_Time.y*1.5*i.fadeset)*0.3+0.7));
			}
			ENDCG
		}
	}
}
