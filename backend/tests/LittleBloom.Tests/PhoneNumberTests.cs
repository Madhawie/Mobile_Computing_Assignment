using LittleBloom.Application.Auth;

namespace LittleBloom.Tests;

public class PhoneNumberTests
{
    [Theory]
    [InlineData("0764823310", "+94764823310")]
    [InlineData("076 482 3310", "+94764823310")]
    [InlineData("+94764823310", "+94764823310")]
    [InlineData("94764823310", "+94764823310")]
    [InlineData("", "")]
    public void Normalize_brings_numbers_to_plus94_format(string input, string expected)
    {
        Assert.Equal(expected, PhoneNumber.Normalize(input));
    }
}
