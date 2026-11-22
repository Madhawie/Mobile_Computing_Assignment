namespace LittleBloom.Application.Auth;

/// <summary>Brings Sri Lankan numbers to one format, so "076 482 3310" and "+94764823310" are the same login.</summary>
public static class PhoneNumber
{
    public static string Normalize(string? input)
    {
        if (string.IsNullOrWhiteSpace(input)) return string.Empty;

        var digits = new string(input.Where(c => char.IsDigit(c) || c == '+').ToArray());

        if (digits.StartsWith("+94")) return digits;
        if (digits.StartsWith("94") && digits.Length == 11) return "+" + digits;
        if (digits.StartsWith('0') && digits.Length == 10) return "+94" + digits[1..];
        return digits;
    }
}
