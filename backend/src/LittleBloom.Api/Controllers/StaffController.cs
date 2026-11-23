using LittleBloom.Api.Auth;
using LittleBloom.Application.Staff;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LittleBloom.Api.Controllers;

/// <summary>Staff accounts of the admin's MOH division (api.md section 9.6). Other roles get 403.</summary>
[ApiController]
[Route("api/staff")]
[Authorize(Roles = "admin")]
public class StaffController : ControllerBase
{
    private readonly IStaffService _staff;

    public StaffController(IStaffService staff) => _staff = staff;

    [HttpGet]
    public async Task<ActionResult<List<StaffDto>>> List(CancellationToken ct)
        => Ok(await _staff.ListAsync(CurrentUserReader.Read(User), ct));

    /// <summary>Add a PHM or supervisor. 201 with the new account, 409 if the phone is already used.</summary>
    [HttpPost]
    public async Task<ActionResult<StaffDto>> Create(CreateStaffBody body, CancellationToken ct)
    {
        var created = await _staff.CreateAsync(CurrentUserReader.Read(User), body, ct);
        return Created($"/api/staff/{created.Id}", created);
    }

    /// <summary>Sign out every phone of this person (lost phone).</summary>
    [HttpPost("{id:guid}/revoke")]
    public async Task<ActionResult<RevokeStaffResponse>> Revoke(Guid id, CancellationToken ct)
        => Ok(await _staff.RevokeAsync(CurrentUserReader.Read(User), id, ct));
}
