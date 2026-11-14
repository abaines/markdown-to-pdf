# Scripts Fixture

Scripts in the Markdown must not run while the PDF renders.
If the script below runs, it adds 20 pages, so the PDF should have exactly 1.

<script>
for (let i = 0; i < 20; i++) {
    document.body.insertAdjacentHTML('beforeend', '<div style="page-break-before: always">script ran</div>');
}
</script>
