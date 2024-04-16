import csv
import argparse

def extract_papers_and_authors(file_path):
    papers = {}
    current_id = None
    current_title = ""
    authors = []

    with open(file_path, newline='', encoding='utf-8') as csvfile:
        reader = csv.reader(csvfile)
        next(reader)  # Skip header row if it exists

        for row in reader:
            if row[0].strip():  # New paper ID starts here
                if current_id is not None:
                    papers[current_id] = {"title": current_title, "authors": authors}

                current_id = row[0].strip()
                current_title = row[1].strip('"')  # Remove surrounding quotes if present
                authors = [f"{row[2]} {row[3]} ({row[4]})"]
            else:  # Continuation of the current paper
                authors.append(f"{row[2]} {row[3]} ({row[4]})")

        # Add the last paper
        if current_id is not None:
            papers[current_id] = {"title": current_title, "authors": authors}

    return papers

def print_papers(papers):
    for paper_id, info in papers.items():
        print(f"{paper_id}: {info['title']}")
        for author in info['authors']:
            print(f"  - {author}")
        print()

def print_papers_html(papers):
    print("<html><body><ol>")
    for paper_id, info in papers.items():
        print(f"<li><strong>{info['title']}</strong><br>")
        print(", ".join(info['authors']))
        print("<p></p></li>")
    print("</ol></body></html>")

def main():
    parser = argparse.ArgumentParser(description='Generate HTML or plain text output of paper listings from a CSV file.')
    parser.add_argument('file_path', type=str, help='Path to the CSV file containing the paper data')
    parser.add_argument('--stdout', type=str, choices=['html', 'text'], default='text', help='Output format (default: text)')

    args = parser.parse_args()

    papers = extract_papers_and_authors(args.file_path)

    if args.stdout == 'html':
        print_papers_html(papers)
    else:
        print_papers(papers)

if __name__ == "__main__":
    main()
