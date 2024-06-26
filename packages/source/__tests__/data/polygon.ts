import type { FeatureCollection, Geometries, Properties } from '@turf/helpers';

const Polygon: FeatureCollection<Geometries, Properties> = {
  type: 'FeatureCollection',
  features: [
    {
      type: 'Feature',
      properties: {
        name: 'tom',
      },
      geometry: {
        type: 'Polygon',
        coordinates: [
          [
            [114.25077438354492, 30.600093873550072],
            [114.26502227783203, 30.600093873550072],
            [114.26502227783203, 30.60807236997211],
            [114.25077438354492, 30.60807236997211],
            [114.25077438354492, 30.600093873550072],
          ],
        ],
      },
    },
    {
      type: 'Feature',
      properties: {
        name: 'joy',
      },
      geometry: {
        type: 'Polygon',
        coordinates: [
          [
            [114.31137084960938, 30.600093873550072],
            [114.30656433105469, 30.589602628298536],
            [114.31549072265625, 30.571572765814274],
            [114.32167053222655, 30.593149091802424],
            [114.32424545288086, 30.59965060448085],
            [114.31137084960938, 30.600093873550072],
          ],
        ],
      },
    },
    {
      type: 'Feature',
      properties: {
        name: 'dog',
      },
      geometry: {
        type: 'Polygon',
        coordinates: [
          [
            [114.26004409790039, 30.57024256120887],
            [114.24373626708983, 30.563886887421297],
            [114.25472259521484, 30.555756930350302],
            [114.26776885986328, 30.55560910664438],
            [114.27618026733398, 30.56832112235078],
            [114.26004409790039, 30.57024256120887],
          ],
        ],
      },
    },
  ],
};

export default Polygon;
