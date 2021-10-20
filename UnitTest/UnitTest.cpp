#include "pch.h"
#include "CppUnitTest.h"
#include "../Fractal/Util.h"
#include <string>
#include <string_view>
#include <vector>
#include <cmath>

using namespace Microsoft::VisualStudio::CppUnitTestFramework;

namespace Microsoft::VisualStudio::CppUnitTestFramework
{
	template<>
	std::wstring ToString(const std::vector<std::string> &q)
	{
		std::wstring res = L"{ ";
		for (bool comma = false; auto & elem : q)
		{
			if (comma)
			{
				res += L", ";
			}
			comma = true;
			res.append(elem.begin(), elem.end());
		}
		if (q.size())
		{
			res += L" ";
		}
		res += L"}";
		return res;
	}
}

// minimal class to test the hlsl stuff as well
class float3
{
public:
	float3(float x, float y, float z) : x(x), y(y), z(z)
	{
	}
	float x, y, z;
};

float length(const float3 &vec)
{
	return sqrtf(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z);
}

float dot(const float3 &vec1, const float3 &vec2)
{
	return vec1.x * vec2.x + vec1.y * vec2.y + vec1.z * vec2.z;
}

bool close(float f1, float f2)
{
	return abs(f1 - f2) < 0.001f;
}

// assumes dir is already normalized
float sdSphereFast(float3 pos, float3 dir, float r)
{
	float b = -dot(pos, dir);
	float c = dot(pos, pos) - r * r;

	float discriminant = b * b - c;
	if (discriminant < 0.f) // no hit
	{
		return b > 0.f ? b : FLT_MAX;
	}
	else // we got a hit
	{
		float root = sqrt(discriminant);
		float t1 = b - root; // smaller one
		float t2 = b + root; // bigger one
		return t1 < 0.f ? t2 : t1;
	}
}

namespace UnitTest
{
	TEST_CLASS(UnitTest)
	{
	public:
		static std::vector<std::string> stringify(const std::vector<std::string_view> &input)
		{
			return std::vector<std::string>(input.begin(), input.end());
		}

		// test the simple case
		TEST_METHOD(TestStringSplit1)
		{
			std::string input = "hello;world";
			std::vector<std::string> expected_parts = { "hello", "world" };
			std::vector<std::string> expected_sep = { ";" };

			auto [parts, sep] = splitString(input, ";");

			Assert::AreEqual(expected_parts, stringify(parts));
			Assert::AreEqual(expected_sep, stringify(sep));
		}

		// test longer string
		TEST_METHOD(TestStringSplit2)
		{
			std::string input = "hello<>world";
			std::vector<std::string> expected_parts = { "hello", "world" };
			std::vector<std::string> expected_sep = { "<>" };

			auto [parts, sep] = splitString(input, "<>");

			Assert::AreEqual(expected_parts, stringify(parts));
			Assert::AreEqual(expected_sep, stringify(sep));
		}

		// test the same string, but split
		TEST_METHOD(TestStringSplit3)
		{
			std::string input = "hello<>world";
			std::vector<std::string> expected_parts = { "hello", "world" };
			std::vector<std::string> expected_sep = { "<>" };

			auto [parts, sep] = splitString(input, "<", ">");

			Assert::AreEqual(expected_parts, stringify(parts));
			Assert::AreEqual(expected_sep, stringify(sep));
		}

		// test with some extra stuff in between
		TEST_METHOD(TestStringSplit4)
		{
			std::string input = "hello<abc>world";
			std::vector<std::string> expected_parts = { "hello", "world" };
			std::vector<std::string> expected_sep = { "<abc>" };

			auto [parts, sep] = splitString(input, "<", ">");

			Assert::AreEqual(expected_parts, stringify(parts));
			Assert::AreEqual(expected_sep, stringify(sep));
		}

		// test with a longer string
		TEST_METHOD(TestStringSplit5)
		{
			std::string input = "hello<abc>world<def>";
			std::vector<std::string> expected_parts = { "hello", "world", "" };
			std::vector<std::string> expected_sep = { "<abc>", "<def>" };

			auto [parts, sep] = splitString(input, "<", ">");

			Assert::AreEqual(expected_parts, stringify(parts));
			Assert::AreEqual(expected_sep, stringify(sep));
		}

		// test with a longer string
		TEST_METHOD(TestStringSplit6)
		{
			std::string input = "hello<abc>world<def>huhu";
			std::vector<std::string> expected_parts = { "hello", "world", "huhu" };
			std::vector<std::string> expected_sep = { "<abc>", "<def>" };

			auto [parts, sep] = splitString(input, "<", ">");

			Assert::AreEqual(expected_parts, stringify(parts));
			Assert::AreEqual(expected_sep, stringify(sep));
		}

		// test with some partial separators
		TEST_METHOD(TestStringSplit7)
		{
			std::string input = "hello<abc>wo<rld<def>huhu";
			std::vector<std::string> expected_parts = { "hello", "wo", "huhu" };
			std::vector<std::string> expected_sep = { "<abc>", "<rld<def>" };

			auto [parts, sep] = splitString(input, "<", ">");

			Assert::AreEqual(expected_parts, stringify(parts));
			Assert::AreEqual(expected_sep, stringify(sep));
		}

		// test SDFs
		// test fast sphere
		// normal case, one hit
		TEST_METHOD(TestFastSphere1)
		{
			float distance = sdSphereFast({ -4.f, 0.f, 0.f }, { 1.f, 0.f, 0.f }, 1.f);
			float expected = 3.f;
			Assert::IsTrue(close(distance, expected));
		}

		// miss it but get the closest point
		TEST_METHOD(TestFastSphere2)
		{
			float distance = sdSphereFast({ -4.f, 2.f, 0.f }, { 1.f, 0.f, 0.f }, 1.f);
			float expected = 4.f;
			Assert::IsTrue(close(distance, expected));
		}

		// no hit and no closest point, edge case
		TEST_METHOD(TestFastSphere3)
		{
			float distance = sdSphereFast({ 0.f, 2.f, 0.f }, { 1.f, 0.f, 0.f }, 1.f);
			float expected = FLT_MAX;
			Assert::IsTrue(close(distance, expected));
		}

		// no hit and no closest point, normal case
		TEST_METHOD(TestFastSphere4)
		{
			float distance = sdSphereFast({ 0.f, 2.f, 0.f }, { 1.f, 0.1f, 0.f }, 1.f);
			float expected = FLT_MAX;
			Assert::IsTrue(close(distance, expected));
		}

		// inside on one side
		TEST_METHOD(TestFastSphere5)
		{
			float distance = sdSphereFast({ 0.5f, 0.f, 0.f }, { 1.f, 0.f, 0.f }, 1.f);
			float expected = 0.5f;
			Assert::IsTrue(close(distance, expected));
		}

		// inside on the far side
		TEST_METHOD(TestFastSphere6)
		{
			float distance = sdSphereFast({ -0.5f, 0.f, 0.f }, { 1.f, 0.f, 0.f }, 1.f);
			float expected = 1.5f;
			Assert::IsTrue(close(distance, expected));
		}
	};
}
