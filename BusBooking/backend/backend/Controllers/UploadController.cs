using Microsoft.AspNetCore.Mvc;
using System.IO;
using System.Linq;

namespace backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UploadController : ControllerBase
    {
        private readonly string _uploadRoot;

        public UploadController(IWebHostEnvironment env)
        {
            _uploadRoot = Path.Combine(env.WebRootPath ?? "wwwroot", "uploads", "buses");
            Directory.CreateDirectory(_uploadRoot);
        }

        /// <summary>
        /// Upload bus image and return public URL.
        /// </summary>
        [HttpPost("bus-image")]
        [RequestSizeLimit(20 * 1024 * 1024)] // 20MB limit
        public async Task<IActionResult> UploadBusImage([FromForm] IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest(new { message = "Không có file tải lên" });
            }

            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            if (!allowed.Contains(extension))
            {
                return BadRequest(new { message = "Định dạng file không được hỗ trợ. Chỉ hỗ trợ JPG, PNG, WEBP." });
            }

            var fileName = $"{Guid.NewGuid():N}{extension}";
            var savePath = Path.Combine(_uploadRoot, fileName);

            await using (var stream = System.IO.File.Create(savePath))
            {
                await file.CopyToAsync(stream);
            }

            var baseUrl = $"{Request.Scheme}://{Request.Host}";
            var fileUrl = $"{baseUrl}/uploads/buses/{fileName}";

            return Ok(new { url = fileUrl, fileName });
        }
    }
}
