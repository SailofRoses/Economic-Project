import asyncio
import concurrent.futures
import pdfkit
import os
from tqdm import tqdm

options = {"javascript-delay": 2000}  # Delay in milliseconds
retry_attempts = 3  # Number of retry attempts for each URL
failed_urls = []  # List to keep track of failed URLs


def fetch_and_save(url):
    global retry_attempts
    output_dir = "pdfs"
    os.makedirs(output_dir, exist_ok=True)
    output_file = os.path.join(
        output_dir, f"{url[8:]}.pdf".replace("/", "_").replace("?", "-")
    )
    try:
        pdfkit.from_url(url, output_file, options=options)
        print(f"Successfully saved: {url} -> {output_file}")
    except Exception as e:
        retry_attempts -= 1
        if retry_attempts > 0:
            print(f"Retrying {url} ({retry_attempts} attempts left)")
            fetch_and_save(url)
        else:
            failed_urls.append(url)
            print(f"Error fetching {url}: {e}")


async def run_fetches(urls, max_workers=8):
    loop = asyncio.get_event_loop()
    # Use a thread pool to run pdfkit calls concurrently
    with concurrent.futures.ThreadPoolExecutor(
        max_workers=max_workers
    ) as executor:
        tasks = [
            loop.run_in_executor(executor, fetch_and_save, url) for url in urls
        ]
        for future in tqdm(
            asyncio.as_completed(tasks),
            total=len(tasks),
            desc="Processing URLs",
        ):
            await future


if __name__ == "__main__":
    # TODO: Replace with your list of 7000 website URLs
    urls = [
        "https://stackoverflow.com/questions/27673870/cant-create-pdf-using-python-pdfkit-error-no-wkhtmltopdf-executable-found?noredirect=1&lq=1",
        "https://stackoverflow.com/questions/23359083/how-to-convert-webpage-into-pdf-by-using-python",
    ]
    asyncio.run(run_fetches(urls, max_workers=16))
    print(f"Failed URLs: {failed_urls}")
