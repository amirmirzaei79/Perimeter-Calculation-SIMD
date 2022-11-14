#include <stdio.h>
#include <math.h>

void read_array(float[], float[], int);
float find_perimeter(float[], float[], int);

int main()
{
    int n;
    scanf("%d", &n);
    float x_points[n], y_points[n];
    read_array(x_points, y_points, n);
    float res = find_perimeter(x_points, y_points, n);
    printf("%f\n", res);
}

void read_array(float x_points[], float y_points[], int n)
{
    for (int i = 0; i < n; i++)
        scanf("%f %f", &x_points[i], &y_points[i]);
}

/*
float find_perimeter(float x_points[], float y_points[], int n)
{
    float sum = 0;
    for (int i = 0; i < n; i++)
    {
        float edge;
        if (i == n - 1)
            edge = sqrtf(
                ((x_points[0] - x_points[i]) * (x_points[0] - x_points[i])) +
                ((y_points[0] - y_points[i]) * (y_points[0] - y_points[i])));
        else
            edge = sqrtf(
                ((x_points[i] - x_points[i + 1]) * (x_points[i] - x_points[i + 1])) +
                ((y_points[i] - y_points[i + 1]) * (y_points[i] - y_points[i + 1])));

        sum += edge;
        printf("%f\n", edge);
    }

    return sum;
}
*/
