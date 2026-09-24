using FluentAssertions;
using NovadisApi.Services.Auth;

namespace NovadisApi.Tests.Services;

public class CodeGeneratorServiceTests
{
    private readonly CodeGeneratorService _sut = new();

    [Fact]
    public void GenerateCode_DefaultLength_Returns6Digits()
    {
        var code = _sut.GenerateCode();
        code.Should().HaveLength(6);
        code.Should().MatchRegex("^\\d{6}$");
    }

    [Theory]
    [InlineData(4)]
    [InlineData(8)]
    [InlineData(10)]
    public void GenerateCode_CustomLength_ReturnsCorrectLength(int length)
    {
        var code = _sut.GenerateCode(length);
        code.Should().HaveLength(length);
        code.Should().MatchRegex($"^\\d{{{length}}}$");
    }

    [Fact]
    public void GenerateCode_ProducesDifferentCodes_OverManyCalls()
    {
        // 1000 codes — collisions extrêmement improbables si RNG cryptographique
        var codes = Enumerable.Range(0, 1000).Select(_ => _sut.GenerateCode()).ToList();
        var unique = codes.Distinct().Count();
        unique.Should().BeGreaterThan(950, "le RNG cryptographique doit éviter les répétitions massives");
    }

    [Fact]
    public void HashCode_SameInputAndSalt_ProducesSameHash()
    {
        var salt = _sut.GenerateSalt();
        _sut.HashCode("123456", salt).Should().Be(_sut.HashCode("123456", salt));
    }

    [Fact]
    public void HashCode_DifferentInput_ProducesDifferentHash()
    {
        var salt = _sut.GenerateSalt();
        _sut.HashCode("123456", salt).Should().NotBe(_sut.HashCode("654321", salt));
    }

    [Fact]
    public void HashCode_SameCodeDifferentSalt_ProducesDifferentHash()
    {
        // Le sel par tentative interdit une table précalculée commune à toutes les tentatives.
        _sut.HashCode("123456", _sut.GenerateSalt()).Should().NotBe(_sut.HashCode("123456", _sut.GenerateSalt()));
    }

    [Fact]
    public void GenerateSalt_Returns16RandomBytes()
    {
        var salt = _sut.GenerateSalt();
        Convert.FromBase64String(salt).Should().HaveCount(16);
        salt.Should().NotBe(_sut.GenerateSalt());
    }

    [Fact]
    public void VerifyCode_CorrectCode_ReturnsTrue()
    {
        var salt = _sut.GenerateSalt();
        var hash = _sut.HashCode("987654", salt);
        _sut.VerifyCode("987654", hash, salt).Should().BeTrue();
    }

    [Fact]
    public void VerifyCode_WrongCode_ReturnsFalse()
    {
        var salt = _sut.GenerateSalt();
        var hash = _sut.HashCode("987654", salt);
        _sut.VerifyCode("000000", hash, salt).Should().BeFalse();
    }

    [Fact]
    public void VerifyCode_WrongSalt_ReturnsFalse()
    {
        var hash = _sut.HashCode("987654", _sut.GenerateSalt());
        _sut.VerifyCode("987654", hash, _sut.GenerateSalt()).Should().BeFalse();
    }

    [Fact]
    public void VerifyCode_MalformedHash_ReturnsFalse()
    {
        _sut.VerifyCode("987654", "pas du base64 !", _sut.GenerateSalt()).Should().BeFalse();
    }
}
