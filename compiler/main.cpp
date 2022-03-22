#include <bits/stdc++.h>
using namespace std;

typedef int int_ptr;

inline int div_ceil(int d, int q){
    return (d/q + (d%q != 0));
}

const int NU_COUNT = 4;
const int XY_OFFSET_START = NU_COUNT;
const int W_OFFSET_START = NU_COUNT;

struct Matrix{
    int m,n;
    int_ptr offset;
};

struct Vector{
    int m;
    int_ptr offset;
};

struct Layer{
    Matrix weights;
    Vector x, v, y;
    int activation_function_mask = 0;
};

class NeuralNetwork {
private:

    void forward_propagate(const Layer& layer){
        int w_index = layer.weights.offset;
        int y_index = layer.y.offset;
        int v_index = layer.v.offset;

        while((w_index-layer.weights.offset) < layer.weights.n*div_ceil(layer.weights.m, NU_COUNT)){
            for(int x_index = layer.x.offset, i = 0; i < layer.x.m; x_index++, w_index++, i++)
                //cout << "\tMATMUL " << w_index << "," << x_index << endl;
                cout << "matmul(" << w_index << "," << x_index << ");" << endl;
            
            int i;
            for(i = 0; (i != NU_COUNT) && ((y_index-layer.y.offset) < layer.y.m); i++,  y_index++)
                //cout << "\tACCTOXY " << y_index << "," << layer.activation_function_mask << endl;
                cout << "acc_mov(" << y_index << ",1," << layer.activation_function_mask << ");" << endl;
                // bypass 0

                
            if(train){
                while(i++ != NU_COUNT)
                    //cout << "\tNOP" << endl;
                    cout << "nop();" << endl;
                
                for(i = 0; (i != NU_COUNT) && ((v_index-layer.v.offset) < layer.v.m); i++,  v_index++){
                    //cout << "\tACCTOXY " << y_index << "," << layer.activation_function_mask << endl;
                    cout << "acc_mov(" << v_index << ",1," << layer.activation_function_mask << ");" << endl;                
                }
            }
        }
    }

public:
    Layer *layers;
    int depth;
    bool train;

    NeuralNetwork(int *layer_sizes, int _depth, bool _train = false) : depth(_depth), train(_train)
    {
        layers = new Layer[_depth];
        layers[0].weights = {
            .m = 0,
            .n = 0,
            .offset = W_OFFSET_START
        };

        layers[0].y = {
            .m = layer_sizes[0],
            .offset = XY_OFFSET_START
        };

        for(int i=1; i < depth; i++){
            layers[i].x = {
                .m = layer_sizes[i-1],
                .offset = layers[i-1].y.offset
            };

            if(train){
                layers[i].v = {
                    .m = layer_sizes[i],
                    .offset = layers[i].x.offset + layers[i].x.m
                };

                layers[i].y = {
                    .m = layer_sizes[i],
                    .offset = layers[i].v.offset + layers[i].v.m
                };
            }
            else
                layers[i].y = {
                    .m = layer_sizes[i],
                    .offset = layers[i].x.offset + layers[i].x.m
                };

            layers[i].weights = {
                .m = layers[i].y.m,
                .n = layers[i].x.m,
                .offset = layers[i-1].weights.offset + layers[i-1].weights.n*div_ceil(layers[i-1].weights.m, NU_COUNT)
            };
        }
    }

    ~NeuralNetwork(){
        delete[] layers;
    }

    void predict(){
        for(int i = 1; i < depth; i++){
            cout << "_layer" << i << ":" << endl;
            forward_propagate(layers[i]);
        }
    }

};


int main(){
    int layer_sizes[] = {3,4,5,2};
    NeuralNetwork nn(layer_sizes, sizeof(layer_sizes)/sizeof(int), true);
    nn.predict();


    return 0;

}