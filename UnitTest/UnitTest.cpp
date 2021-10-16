#include "pch.h"
#include "CppUnitTest.h"
#include "../Fractal/Util.h"
#include <string>
#include <string_view>
#include <vector>

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
	};
}
