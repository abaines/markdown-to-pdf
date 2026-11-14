# Script test

If scripts run, the script below adds a marker line and 20 extra pages.

<script>
document.body.insertAdjacentHTML('beforeend', '<p>SCRIPT-RAN</p>');
for (let i = 0; i < 20; i++) {
    document.body.insertAdjacentHTML('beforeend', '<div style="page-break-before: always">extra page</div>');
}
</script>
