(function () {
	const chartRoot = document.querySelector('.js-line-chart[data-chart-id="user-growth"]');

	if (!chartRoot) return;

	const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
	const datasets = {
		current: {
			label: 'This year',
			color: '#4A90E2',
			values: [540, 780, 930, 880, 1120, 1280, 1410, 1380, 1500, 400, 0, 0],
		},
	};

	const state = { activeKey: 'current' };
	const svg = chartRoot.querySelector('svg');
	const xAxis = chartRoot.querySelector('.chart__axis--x');
	const yAxis = chartRoot.querySelector('.chart__axis--y');
	const grid = chartRoot.querySelector('.chart__grid');
	const canvas = chartRoot.querySelector('.chart__canvas');
	const margin = { left: 24, right: 48 };
	const verticalPadding = { top: 24, bottom: 8 };

	const withAlpha = (hex, alpha) => {
		const safeHex = hex.replace('#', '');
		const bigint = parseInt(safeHex, 16);
		const r = (bigint >> 16) & 255;
		const g = (bigint >> 8) & 255;
		const b = bigint & 255;
		return `rgba(${r}, ${g}, ${b}, ${alpha})`;
	};

	const buildYAxis = (values) => {
		const maxValue = Math.max(...values, 0);
		const paddedMax = Math.max(maxValue + Math.max(maxValue * 0.1, 40), 1);
		const roughStep = paddedMax / 5 || 1;
		const magnitude = Math.pow(10, Math.floor(Math.log10(roughStep)));
		const niceStep = Math.ceil(roughStep / magnitude) * magnitude;
		const ceiling = Math.max(niceStep * 5, paddedMax || niceStep);
		const ticks = [];

		for (let i = 5; i >= 0; i -= 1) {
			ticks.push(i * niceStep);
		}

		return { ticks, ceiling };
	};

	const renderGrid = (lines) => {
		grid.innerHTML = lines.map(() => '<span class="chart__grid-line"></span>').join('');
	};

	const renderAxes = (labels, ticks) => {
		xAxis.innerHTML = labels.map((label) => `<span>${label}</span>`).join('');
		yAxis.innerHTML = ticks.map((tick) => `<span>${tick}</span>`).join('');
	};

	const buildPath = (values, palette) => {
		const height = 220;
		const width = 960;
		const innerWidth = width - margin.left - margin.right;
		const validValues = values.filter((v) => v > 0);
		const { ticks, ceiling } = buildYAxis(validValues);
		const max = ceiling || 1;
		const step = innerWidth / Math.max(values.length - 1, 1);
		const chartHeight = height - verticalPadding.top - verticalPadding.bottom;
		const baselineY = height - verticalPadding.bottom;

		const allPoints = values.map((value, index) => {
			if (!(value > 0)) return null;
			const x = margin.left + index * step;
			const y = verticalPadding.top + (chartHeight - (value / max) * chartHeight);
			return { x, y };
		});

		const segments = [];
		let current = [];
		allPoints.forEach((point) => {
			if (point) {
				current.push(point);
			} else if (current.length) {
				segments.push(current);
				current = [];
			}
		});
		if (current.length) segments.push(current);

		const buildSmoothLine = (points) => {
			if (points.length === 1) return `M${points[0].x},${points[0].y}`;
			let d = `M${points[0].x},${points[0].y}`;

			for (let i = 1; i < points.length - 1; i += 1) {
				const currentPoint = points[i];
				const nextPoint = points[i + 1];
				const midX = (currentPoint.x + nextPoint.x) / 2;
				const midY = (currentPoint.y + nextPoint.y) / 2;
				d += ` Q${currentPoint.x},${currentPoint.y} ${midX},${midY}`;
			}

			const last = points[points.length - 1];
			d += ` T${last.x},${last.y}`;
			return d;
		};

		const linePaths = segments.map((segment) => buildSmoothLine(segment)).join(' ');
		const areaPaths = segments
			.map((segment) => {
				const start = segment[0];
				const end = segment[segment.length - 1];
				const path = buildSmoothLine(segment);
				return `${path} L${end.x},${baselineY} L${start.x},${baselineY} Z`;
			})
			.join(' ');

		return { ticks, ceiling: max, line: linePaths, area: areaPaths, width, height };
	};

	const renderChart = (datasetKey) => {
		const series = datasets[datasetKey];
		if (!series) return;

		const { line, area, ticks, width, height } = buildPath(series.values, series);

		svg.setAttribute('viewBox', `0 0 ${width} ${height}`);
		svg.innerHTML = `
      <path class="chart__area" fill="${withAlpha(series.color, 0.12)}" d="${area}" />
      <path class="chart__line" stroke="${series.color}" d="${line}" />
    `;

		canvas.setAttribute('aria-label', `${series.label} monthly user growth`);

		renderAxes(months, ticks);
		renderGrid(ticks);
	};

	renderChart(state.activeKey);

	window.superadminChart = {
		update: (key, values) => {
			if (!datasets[key]) return;
			datasets[key].values = values;
			state.activeKey = key;
			renderChart(key);
		},
	};
})();
