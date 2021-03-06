RSpec.describe Spree::Api::RelationsController, type: :controller do
  stub_authorization!
  render_views

  let(:user)     { create(:user) }
  let!(:product) { create(:product) }
  let!(:other1)  { create(:product) }

  let!(:relation_type) { create(:relation_type) }
  let!(:relation) { create(:relation, relatable: product, related_to: other1, relation_type: relation_type, position: 0) }

  before { allow(controller).to receive(:spree_current_user).and_return(user) }
  after  { Spree::Admin::ProductsController.clear_overrides! }

  context 'model_class' do
    it 'responds to model_class as Spree::Relation' do
      expect(controller.send(:model_class)).to eq Spree::Relation
    end
  end

  describe 'with JSON' do
    let(:valid_params) do
      {
        format: :json,
        product_id: product.id,
        relation: {
          related_to_id: other1.id,
          relation_type_id: relation_type.id
        }
      }
    end

    context '#create' do
      it 'creates the relation' do
        spree_post :create, valid_params
        expect(response.status).to be(201)
      end

      it 'responds 422 error with invalid params' do
        spree_post :create, format: :json, product_id: product.id
        expect(response.status).to be(422)
      end
    end

    context '#update' do
      it 'succesfully updates the relation ' do
        params = { format: :json, id: relation.id, relation: { discount_amount: 2.0 } }
        expect {
          spree_post :update, params
        }.to change { relation.reload.discount_amount.to_s }.from('0.0').to('2.0')
      end
    end

    context '#destroy with' do
      it 'records successfully' do
        expect {
          spree_delete :destroy, id: 1, product_id: product.id, format: :json
        }.to change(Spree::Relation, :count).by(-1)
      end
    end

    context '#update_positions' do
      it 'returns the correct position of the related products' do
        other2    = create(:product)
        relation2 = create(:relation, relatable: product, related_to: other2, relation_type: relation_type, position: 1)

        expect {
          spree_post :update_positions, id: relation.id, positions: { relation.id => '1', relation2.id => '0' }, format: :json
          relation.reload
        }.to change(relation, :position).from(0).to(1)
      end
    end
  end
end
