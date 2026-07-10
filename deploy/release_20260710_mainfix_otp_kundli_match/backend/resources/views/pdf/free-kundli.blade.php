<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>AstroZura Free Kundli</title>
    <style>
        body { font-family: DejaVu Sans, sans-serif; color: #10233f; font-size: 12px; line-height: 1.45; }
        .header { background: #1e3557; color: #fff; padding: 22px; border-radius: 12px; }
        .brand { font-size: 22px; font-weight: 800; letter-spacing: .5px; }
        .muted { color: #667085; }
        .gold { color: #d4a73c; }
        h2 { margin: 22px 0 10px; color: #1e3557; font-size: 16px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 12px; }
        th { background: #d4a73c; color: #10233f; text-align: left; padding: 8px; font-weight: 800; }
        td { border: 1px solid #e8edf5; padding: 7px; vertical-align: top; }
        tr:nth-child(even) td { background: #f8fafc; }
        .note { margin-top: 18px; padding: 12px; background: #fff7df; border: 1px solid #efd58a; border-radius: 8px; }
    </style>
</head>
<body>
    @php
        $birth = data_get($provider, 'birth_details.data', []);
        $astro = data_get($provider, 'astro_details.data', []);
        $planets = data_get($provider, 'planets.data', []);
        $planetRows = is_array($planets) ? $planets : [];
        $value = function ($item) {
            if (is_array($item)) {
                return $item['name'] ?? $item['full_name'] ?? json_encode($item, JSON_UNESCAPED_UNICODE);
            }
            if ($item === null || $item === '') {
                return '-';
            }
            return (string) $item;
        };
    @endphp

    <div class="header">
        <div class="brand">AstroZura</div>
        <div class="gold">Free Kundli Summary</div>
        <p>Your basic kundli details are generated from the birth information provided on AstroZura.</p>
    </div>

    <h2>Native Details</h2>
    <table>
        <tr><th>Field</th><th>Value</th></tr>
        <tr><td>Name</td><td>{{ $name }}</td></tr>
        <tr><td>Gender</td><td>{{ ucfirst($gender) }}</td></tr>
        <tr><td>Date of Birth</td><td>{{ $dateOfBirth }}</td></tr>
        <tr><td>Time of Birth</td><td>{{ $timeOfBirth }}</td></tr>
        <tr><td>Place of Birth</td><td>{{ $placeOfBirth }}</td></tr>
        <tr><td>Coordinates</td><td>{{ $coordinates }}</td></tr>
    </table>

    <h2>Birth Details</h2>
    <table>
        <tr><th>Field</th><th>Value</th></tr>
        @forelse($birth as $key => $item)
            <tr><td>{{ ucwords(str_replace(['_', '-'], ' ', $key)) }}</td><td>{{ $value($item) }}</td></tr>
        @empty
            <tr><td colspan="2">Birth details are not available in the current API response.</td></tr>
        @endforelse
    </table>

    <h2>Astro Details</h2>
    <table>
        <tr><th>Field</th><th>Value</th></tr>
        @forelse($astro as $key => $item)
            <tr><td>{{ ucwords(str_replace(['_', '-'], ' ', $key)) }}</td><td>{{ $value($item) }}</td></tr>
        @empty
            <tr><td colspan="2">Astro details are not available in the current API response.</td></tr>
        @endforelse
    </table>

    <h2>Planetary Positions</h2>
    <table>
        <tr>
            <th>Planet</th>
            <th>Sign</th>
            <th>Degree</th>
            <th>Nakshatra</th>
            <th>House</th>
        </tr>
        @forelse($planetRows as $planet)
            <tr>
                <td>{{ $value($planet['name'] ?? $planet['planet'] ?? '-') }}</td>
                <td>{{ $value($planet['sign'] ?? $planet['zodiac'] ?? $planet['rasi'] ?? '-') }}</td>
                <td>{{ $value($planet['degree'] ?? $planet['norm_degree'] ?? $planet['full_degree'] ?? '-') }}</td>
                <td>{{ $value($planet['nakshatra'] ?? $planet['nakshatra_name'] ?? '-') }}</td>
                <td>{{ $value($planet['house'] ?? $planet['house_number'] ?? '-') }}</td>
            </tr>
        @empty
            <tr><td colspan="5">Planetary positions are not available in the current API response.</td></tr>
        @endforelse
    </table>

    <div class="note">
        This free Kundli is a basic generated summary. For complete predictions, dosha analysis, dasha, remedies, and divisional charts, use Detailed Kundali Analysis on AstroZura.
    </div>
</body>
</html>
