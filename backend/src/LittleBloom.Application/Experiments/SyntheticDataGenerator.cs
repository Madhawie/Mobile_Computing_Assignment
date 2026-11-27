using LittleBloom.Domain.Entities;

namespace LittleBloom.Application.Experiments;

/// <summary>Body of POST /api/experiments/seed. Only Mothers and AreaId are needed.</summary>
/// <param name="Mothers">How many mothers (E1: 50 / 500 / 5000). 1 to 10 000.</param>
/// <param name="AreaId">PHM area to put them in, e.g. "glg-east".</param>
/// <param name="Seed">Same seed → exactly the same data, so runs can be repeated.</param>
public record SeedRequest(
    int Mothers,
    string AreaId,
    int Seed = 42,
    int ChildrenPerMother = 1,
    int VisitsPerMother = 2,
    int GrowthPerChild = 3,
    int VaccinationsPerChild = 2);

public record SeedResponse(
    int Mothers,
    int MaternalVisits,
    int Children,
    int GrowthMeasurements,
    int Vaccinations,
    long FirstChangeSeq,
    long LastChangeSeq);

public record SyntheticData(
    List<Mother> Mothers,
    List<MaternalVisit> MaternalVisits,
    List<Child> Children,
    List<GrowthMeasurement> GrowthMeasurements,
    List<Vaccination> Vaccinations)
{
    /// <summary>Parents first, so a pull never delivers a child before its mother.</summary>
    public IEnumerable<SyncEntity> All =>
        Mothers.Cast<SyncEntity>().Concat(Children).Concat(MaternalVisits).Concat(GrowthMeasurements).Concat(Vaccinations);

    public int Count => Mothers.Count + MaternalVisits.Count + Children.Count + GrowthMeasurements.Count + Vaccinations.Count;
}

/// <summary>
/// Makes realistic but completely made-up records for the experiments (E1: data volume).
/// Names are common Sri Lankan first names and surnames combined at random; phone numbers are
/// random and never receive an SMS. Never real patient data. Uses a fixed seed, so the same request
/// always gives the same data (same ids, same values) and experiment runs can be repeated.
/// Every value stays inside the RecordValidator limits.
/// </summary>
public static class SyntheticDataGenerator
{
    public const string DeviceId = "seed-generator";
    public const int MaxMothers = 10_000;

    private static readonly string[] FirstNames =
    [
        "Nadeesha", "Dilani", "Kumari", "Sanduni", "Tharushi", "Ishara", "Chathurika", "Nimali",
        "Anusha", "Kavitha", "Tharani", "Fathima", "Rizana", "Sithara", "Malini", "Hasini",
    ];

    private static readonly string[] Surnames =
    [
        "Perera", "Fernando", "Silva", "Jayasinghe", "Bandara", "Rathnayake", "Herath", "Dissanayake",
        "Gunawardena", "Weerasinghe", "Ekanayake", "Nadarajah", "Sivakumar", "Mohamed",
    ];

    private static readonly string[] ChildNames =
    [
        "Senuli", "Kaveesha", "Dinuli", "Yasiru", "Sahan", "Thisara", "Nethmi", "Ravindu", "Hiruni", "Aadhya",
    ];

    private static readonly string[] Roads = ["Temple Road", "Main Street", "Lake Road", "School Lane", "Station Road"];
    private static readonly string[] VisitNotes = ["Well", "Mild swelling of feet", "Advised iron tablets", "Counselled on diet"];
    private static readonly string[] Vaccines = ["BCG", "Pentavalent", "OPV", "MMR", "JE", "DTP"];

    public static SyntheticData Generate(SeedRequest request, DateTime nowUtc)
    {
        var rng = new Random(request.Seed);
        var today = DateOnly.FromDateTime(nowUtc);
        var data = new SyntheticData([], [], [], [], []);

        for (var m = 0; m < request.Mothers; m++)
        {
            var pregnant = rng.NextDouble() < 0.4;
            var gestation = pregnant ? rng.Next(8, 39) : (int?)null;

            var mother = Stamp(new Mother
            {
                Id = NewId(rng),
                FullName = $"{Pick(rng, FirstNames)} {Pick(rng, Surnames)}",
                Phone = $"+9479{rng.Next(0, 10_000_000):D7}",
                Age = rng.Next(18, 43),
                Address = $"No. {rng.Next(1, 300)}, {Pick(rng, Roads)}",
                AreaId = request.AreaId,
                IsPregnant = pregnant,
                GestationWeeks = gestation,
                DueDate = gestation is int weeks ? today.AddDays((40 - weeks) * 7) : null,
            }, nowUtc);
            data.Mothers.Add(mother);

            for (var v = 0; v < request.VisitsPerMother; v++)
            {
                var systolic = rng.Next(100, 136);
                var visitDate = today.AddDays(-rng.Next(0, 181));
                data.MaternalVisits.Add(Stamp(new MaternalVisit
                {
                    Id = NewId(rng),
                    MotherId = mother.Id,
                    VisitDate = visitDate,
                    GestationWeeks = rng.Next(8, 39),
                    WeightKg = Round(45 + rng.NextDouble() * 35),
                    BpSystolic = systolic,
                    BpDiastolic = rng.Next(60, Math.Min(89, systolic - 10)),
                    Notes = rng.NextDouble() < 0.5 ? Pick(rng, VisitNotes) : null,
                    NextVisit = visitDate.AddDays(28),
                }, nowUtc));
            }

            for (var c = 0; c < request.ChildrenPerMother; c++)
            {
                var ageDays = rng.Next(0, 5 * 365); // birth to 5 years: the CHDR monitoring window
                var child = Stamp(new Child
                {
                    Id = NewId(rng),
                    MotherId = mother.Id,
                    Name = Pick(rng, ChildNames),
                    Sex = rng.Next(2) == 0 ? "boy" : "girl",
                    DateOfBirth = today.AddDays(-ageDays),
                    BirthWeightKg = Round(2.2 + rng.NextDouble() * 1.7),
                    BornAt = "Base Hospital",
                    ChdrNumber = $"CHDR-{data.Children.Count + 1:D6}",
                }, nowUtc);
                data.Children.Add(child);

                for (var g = 0; g < request.GrowthPerChild; g++)
                {
                    var daysOld = rng.Next(0, ageDays + 1);
                    var months = daysOld / 30.4;
                    data.GrowthMeasurements.Add(Stamp(new GrowthMeasurement
                    {
                        Id = NewId(rng),
                        ChildId = child.Id,
                        MeasuredOn = child.DateOfBirth.AddDays(daysOld),
                        // Rough growth curve plus noise; stays well inside the validator limits.
                        WeightKg = Round(Math.Min(3.2 + 0.45 * months, 18) + rng.NextDouble() - 0.5),
                        HeightCm = Round(Math.Min(50 + 1.6 * months, 112) + rng.NextDouble() * 2),
                        Notes = null,
                    }, nowUtc));
                }

                for (var x = 0; x < request.VaccinationsPerChild; x++)
                {
                    data.Vaccinations.Add(Stamp(new Vaccination
                    {
                        Id = NewId(rng),
                        ChildId = child.Id,
                        Vaccine = Vaccines[x % Vaccines.Length],
                        Dose = 1,
                        GivenOn = child.DateOfBirth.AddDays(rng.Next(0, ageDays + 1)),
                        BatchNo = $"B{rng.Next(1000, 9999)}",
                    }, nowUtc));
                }
            }
        }

        return data;
    }

    /// <summary>Sync fields of a brand-new server record.</summary>
    private static T Stamp<T>(T record, DateTime nowUtc) where T : SyncEntity
    {
        record.Version = 1;
        record.UpdatedAt = nowUtc;
        record.DeviceId = DeviceId;
        record.Deleted = false;
        return record;
    }

    /// <summary>A UUID v4 made from the seeded random generator, so ids repeat with the seed.</summary>
    private static Guid NewId(Random rng)
    {
        var bytes = new byte[16];
        rng.NextBytes(bytes);
        bytes[7] = (byte)((bytes[7] & 0x0F) | 0x40); // version 4
        bytes[8] = (byte)((bytes[8] & 0x3F) | 0x80); // RFC 4122 variant
        return new Guid(bytes);
    }

    private static string Pick(Random rng, string[] values) => values[rng.Next(values.Length)];

    private static double Round(double value) => Math.Round(value, 1);
}
