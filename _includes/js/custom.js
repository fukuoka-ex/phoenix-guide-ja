jtd.onReady(function () {
  const versionSelect = document.querySelector('.version-select select');
  jtd.addEvent(versionSelect, 'change', function (e) {
    window.location.href = e.target.value;
  });
});